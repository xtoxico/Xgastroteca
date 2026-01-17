package main

import (
	"fmt"
	"log"
	"math"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"time"
	"xgastroteca/database"
	"xgastroteca/models"
	"xgastroteca/services"
	"xgastroteca/utils"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
)

type ProcessRequest struct {
	URL string `json:"url" binding:"required"`
}

func main() {
	// Ensure data directory exists
	dataPath := "./data/videos"
	if err := os.MkdirAll(dataPath, 0755); err != nil {
		log.Fatalf("Failed to create data directory: %v", err)
	}

	// Ensure GEMINI_API_KEY is set
	if os.Getenv("GEMINI_API_KEY") == "" {
		log.Println("WARNING: GEMINI_API_KEY is not set. AI processing will fail.")
	}

	// Initialize Database
	database.InitDB()

	// Migration: Populate SearchText for existing recipes
	// This ensures that recipes created before the SearchText column was added are searchable
	var allRecipes []models.Recipe
	database.DB.Find(&allRecipes)
	for _, r := range allRecipes {
		// Calling Save triggers the BeforeSave hook which populates SearchText
		database.DB.Save(&r)
	}

	r := gin.Default()

	// CORS Configuration
	// TODO: For production, configure specific AllowedOrigins:
	// []string{"https://xgastroteca.antoniotirado.com", "https://api-xgastroteca.antoniotirado.com", "http://localhost:3000"}
	r.Use(cors.New(cors.Config{
		AllowAllOrigins: true,
		AllowMethods:    []string{"GET", "POST", "PUT", "OPTIONS"},
		AllowHeaders:    []string{"Origin", "Content-Type"},
	}))

	r.Static("/videos", "./data/videos") // Serve videos statically

	r.POST("/api/process", func(c *gin.Context) {
		var req ProcessRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		log.Printf("Processing URL: %s", req.URL)

		// 1. Validate Platform and Extract Info
		source, externalID, err := utils.ExtractVideoInfo(req.URL)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Unsupported platform or invalid URL", "details": err.Error()})
			return
		}

		// Check if recipe already exists (Optimization: check before downloading)
		var existingRecipe models.Recipe
		if err := database.DB.Preload("Ingredients").Preload("Steps").Preload("Tags").Where("source = ? AND external_id = ?", source, externalID).First(&existingRecipe).Error; err == nil {
			log.Printf("Receta duplicada encontrada: Source=%s, ID=%s", source, externalID)
			c.JSON(http.StatusOK, existingRecipe) // Return existing recipe
			return
		}

		// Generate a unique filename to ensure we know the path
		// Using simple timestamp for now. In production, use UUID.
		filename := fmt.Sprintf("video_%d.mp4", time.Now().UnixNano())
		fullPath := filepath.Join(dataPath, filename)

		// Using yt-dlp to download
		// We use -f bestvideo+bestaudio/best to get best quality
		// and --merge-output-format mp4 to ensure we get an mp4 container
		cmd := exec.Command("yt-dlp",
			"-o", fullPath,
			"-f", "bestvideo+bestaudio/best",
			"--merge-output-format", "mp4",
			"--write-thumbnail",
			"--convert-thumbnails", "jpg",
			req.URL,
		)

		// Capture output for debugging
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr

		if err := cmd.Run(); err != nil {
			log.Printf("Error downloading video: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to download video", "details": err.Error()})
			return
		}

		log.Printf("Video downloaded to: %s. Starting AI analysis...", fullPath)

		// Call AI Service
		recipe, err := services.AnalyzeVideo(fullPath)
		if err != nil {
			log.Printf("Error analyzing video: %v", err)
			// Handle "not_a_recipe" check
			if err.Error() == "not_a_recipe" {
				os.Remove(fullPath) // Delete the video
				c.JSON(http.StatusBadRequest, gin.H{"error": "Video is not a food recipe", "code": "NOT_A_RECIPE"})
				return
			}
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to analyze video", "details": err.Error()})
			return
		}

		// Populate Multi-Platform ID
		recipe.Source = source
		recipe.ExternalID = externalID

		// Optimize LocalVideoPath for frontend (URL friendly)
		// Convert "data/videos/video_123.mp4" to "videos/video_123.mp4"
		recipe.LocalVideoPath = "videos/" + filepath.Base(fullPath)

		// Set Thumbnail Path (assumes yt-dlp created .jpg with same basename)
		// data/videos/video_123.mp4 -> data/videos/video_123.jpg
		thumbnailFullPath := strings.TrimSuffix(fullPath, filepath.Ext(fullPath)) + ".jpg"
		recipe.ThumbnailPath = "videos/" + filepath.Base(thumbnailFullPath)

		// Save to Database
		if result := database.DB.Create(recipe); result.Error != nil {
			log.Printf("Error saving to database: %v", result.Error)
			// Although we checked before, race conditions might happen, or other errors
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save recipe", "details": result.Error.Error()})
			return
		}

		log.Printf("Recipe saved with ID: %d", recipe.ID)
		c.JSON(http.StatusOK, recipe)
	})

	// GET /api/recipes - List all recipes (Simplified)
	r.GET("/api/recipes", func(c *gin.Context) {
		// 1. Parse Parameters
		page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
		limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))
		search := c.Query("search")

		if page < 1 {
			page = 1
		}
		if limit < 1 {
			limit = 10
		}

		offset := (page - 1) * limit

		// 2. Build Base Query
		query := database.DB.Model(&models.Recipe{})

		// 3. Apply Search Filter (if exists)
		if search != "" {
			normalizedTerm := "%" + utils.NormalizeString(search) + "%"
			// Search in Normalized Column
			query = query.Where("search_text LIKE ?", normalizedTerm)
		}

		// 4. Count Total (for pagination)
		var total int64
		query.Count(&total)

		// 5. Execute Query with Pagination and Preload Tags
		var recipes []models.Recipe
		result := query.Preload("Tags").
			Order("created_at desc").
			Limit(limit).
			Offset(offset).
			Find(&recipes)

		if result.Error != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
			return
		}

		// 6. Calculate total pages
		totalPages := int(math.Ceil(float64(total) / float64(limit)))

		// 7. Structured Response
		c.JSON(http.StatusOK, gin.H{
			"data": recipes,
			"meta": gin.H{
				"current_page": page,
				"limit":        limit,
				"total_items":  total,
				"total_pages":  totalPages,
			},
		})
	})

	// GET /api/recipes/:id - Get single recipe details
	r.GET("/api/recipes/:id", func(c *gin.Context) {
		id := c.Param("id")
		var recipe models.Recipe

		// Preload everything for detail view
		result := database.DB.Preload("Ingredients").Preload("Steps").Preload("Tags").First(&recipe, id)

		if result.Error != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "Recipe not found"})
			return
		}

		c.JSON(http.StatusOK, recipe)
	})

	log.Println("Server starting on :8080")
	r.Run(":8080")
}
