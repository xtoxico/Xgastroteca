package main

import (
	"log"
	"math"
	"net/http"
	"os"
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

type AddTagRequest struct {
	Name string `json:"name" binding:"required"`
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
	var allRecipes []models.Recipe
	database.DB.Find(&allRecipes)
	for _, r := range allRecipes {
		database.DB.Save(&r)
	}

	// Start Queue Worker
	services.StartQueueWorker()

	r := gin.Default()

	// CORS Configuration
	r.Use(cors.New(cors.Config{
		AllowAllOrigins: true,
		AllowMethods:    []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowHeaders:    []string{"Origin", "Content-Type"},
	}))

	r.Static("/videos", "./data/videos")

	// --- ROUTES ---

	// POST /api/process - Start processing a video
	r.POST("/api/process", func(c *gin.Context) {
		var req ProcessRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		// Call the shared processor service
		recipe, err := services.ProcessVideo(req.URL)
		if err != nil {
			// Check for Quota Error / Rate Limit
			if strings.Contains(err.Error(), "429") || strings.Contains(strings.ToLower(err.Error()), "quota") {
				// Queue the job
				job := models.ProcessingJob{
					URL:         req.URL,
					Status:      models.JobStatusPending,
					NextRetryAt: time.Now().Add(15 * time.Minute),
					ErrorMsg:    "Initial Quota Exceeded",
				}
				database.DB.Create(&job)

				c.JSON(http.StatusAccepted, gin.H{
					"message":  "Quota exceeded. Added to processing queue.",
					"queue_id": job.ID,
					"status":   "queued",
				})
				return
			}

			// Check for "Not a Recipe"
			if err.Error() == "not_a_recipe" {
				c.JSON(http.StatusBadRequest, gin.H{"error": "Video is not a food recipe", "code": "NOT_A_RECIPE"})
				return
			}

			// General Error
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to process video", "details": err.Error()})
			return
		}

		c.JSON(http.StatusOK, recipe)
	})

	// GET /api/queue - List pending jobs
	r.GET("/api/queue", func(c *gin.Context) {
		var jobs []models.ProcessingJob
		database.DB.Order("created_at desc").Find(&jobs)
		c.JSON(http.StatusOK, jobs)
	})

	// DELETE /api/queue/:id - Remove job from queue
	r.DELETE("/api/queue/:id", func(c *gin.Context) {
		id := c.Param("id")
		if err := database.DB.Delete(&models.ProcessingJob{}, id).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete job"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "Job deleted"})
	})

	// POST /api/recipes/:id/tags - Add tag manually
	r.POST("/api/recipes/:id/tags", func(c *gin.Context) {
		id := c.Param("id")
		var req AddTagRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		// Verify recipe exists (optional but good)
		var recipe models.Recipe
		if err := database.DB.First(&recipe, id).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "Recipe not found"})
			return
		}

		tag := models.Tag{
			RecipeID: recipe.ID,
			Name:     req.Name,
		}
		if err := database.DB.Create(&tag).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to add tag"})
			return
		}

		c.JSON(http.StatusCreated, tag)
	})

	// DELETE /api/recipes/:id - Delete recipe
	r.DELETE("/api/recipes/:id", func(c *gin.Context) {
		id := c.Param("id")
		var recipe models.Recipe

		// Get recipe to delete files
		if err := database.DB.First(&recipe, id).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "Recipe not found"})
			return
		}

		// Delete files
		if recipe.LocalVideoPath != "" {
			// LocalVideoPath is like "videos/file.mp4", we need full path "data/videos/file.mp4"
			// But wait, in main.go we serve static from ./data/videos.
			// If stored path is relative to web root, we need to adjust.
			// Stored: "videos/vid.mp4". Static root: "./data/videos".
			// Real path: "./data/" + "videos/vid.mp4" ? No.
			// In processor.go: LocalVideoPath = "videos/" + basename.
			// So real path is ./data/ + basename.

			// Let's reconstruct safely
			basename := filepath.Base(recipe.LocalVideoPath)
			fullVideoPath := filepath.Join(dataPath, basename)
			os.Remove(fullVideoPath)

			// Remove thumbnail too?
			// Thumbnail path logic is similar.
			if recipe.ThumbnailPath != "" {
				thumbBasename := filepath.Base(recipe.ThumbnailPath)
				fullThumbPath := filepath.Join(dataPath, thumbBasename)
				os.Remove(fullThumbPath)
			}
		}

		// Delete from DB (Cascades should be handled by GORM if configured, otherwise manual)
		// Gorm supports soft delete by default for models with gorm.Model.
		// To delete permanently: Unscoped().Delete
		if err := database.DB.Unscoped().Select("Ingredients", "Steps", "Tags").Delete(&recipe).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete recipe"})
			return
		}

		c.JSON(http.StatusOK, gin.H{"message": "Recipe deleted"})
	})

	// GET /api/version - Version Check
	r.GET("/api/version", func(c *gin.Context) {
		backendVersion := "1.1.0"
		latestAppVersion := os.Getenv("LATEST_APP_VERSION") // Defined in docker-compose
		downloadUrl := "https://xgastroteca.antoniotirado.com/app-release.apk"

		if latestAppVersion == "" {
			latestAppVersion = "1.0.0" // Default
		}

		c.JSON(http.StatusOK, gin.H{
			"backend_version":    backendVersion,
			"latest_app_version": latestAppVersion,
			"download_url":       downloadUrl,
		})
	})

	// GET /api/recipes - List all recipes
	r.GET("/api/recipes", func(c *gin.Context) {
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

		query := database.DB.Model(&models.Recipe{})

		if search != "" {
			normalizedTerm := "%" + utils.NormalizeString(search) + "%"
			query = query.Where("search_text LIKE ?", normalizedTerm)
		}

		var total int64
		query.Count(&total)

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

		totalPages := int(math.Ceil(float64(total) / float64(limit)))

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
