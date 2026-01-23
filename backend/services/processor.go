package services

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
	"xgastroteca/database"
	"xgastroteca/models"
	"xgastroteca/utils"
)

// ProcessVideo orchestrates the downloading and AI analysis of a video URL
func ProcessVideo(url string) (*models.Recipe, error) {
	dataPath := "./data/videos"

	log.Printf("Processing URL: %s", url)

	// 1. Validate Platform and Extract Info
	source, externalID, err := utils.ExtractVideoInfo(url)
	if err != nil {
		return nil, fmt.Errorf("invalid URL: %v", err)
	}

	// Check if recipe already exists (Optimization: check before downloading)
	var existingRecipe models.Recipe
	if err := database.DB.Preload("Ingredients").Preload("Steps").Preload("Tags").Where("source = ? AND external_id = ?", source, externalID).First(&existingRecipe).Error; err == nil {
		log.Printf("Receta duplicada encontrada: Source=%s, ID=%s", source, externalID)
		return &existingRecipe, nil
	}

	// Generate a unique filename to ensure we know the path
	filename := fmt.Sprintf("video_%d.mp4", time.Now().UnixNano())
	fullPath := filepath.Join(dataPath, filename)

	// Using yt-dlp to download
	cmd := exec.Command("yt-dlp",
		"-o", fullPath,
		"-f", "bestvideo+bestaudio/best",
		"--merge-output-format", "mp4",
		"--write-thumbnail",
		"--convert-thumbnails", "jpg",
		url,
	)

	// Capture output for debugging (optional, maybe redirect to log if needed)
	// cmd.Stdout = os.Stdout
	// cmd.Stderr = os.Stderr

	if err := cmd.Run(); err != nil {
		log.Printf("Error downloading video: %v", err)
		return nil, fmt.Errorf("failed to download video: %v", err)
	}

	log.Printf("Video downloaded to: %s. Starting AI analysis...", fullPath)

	// Call AI Service
	recipe, err := AnalyzeVideo(fullPath)
	if err != nil {
		log.Printf("Error analyzing video: %v", err)
		// Clean up video if it's not a recipe or if analysis failed
		// But maybe keep it for manual retry if it's just a temporary AI failure?
		// For now, following original logic: delete if not a recipe.
		if err.Error() == "not_a_recipe" {
			os.Remove(fullPath)
			return nil, err // Return specific error
		}

		// If it's another error (e.g. quota), we might want to keep the file?
		// But current logic is to download again which is safer for retry logic simplification
		// os.Remove(fullPath)
		return nil, err
	}

	// Populate Multi-Platform ID
	recipe.Source = source
	recipe.ExternalID = externalID

	// Optimize LocalVideoPath for frontend (URL friendly)
	recipe.LocalVideoPath = "videos/" + filepath.Base(fullPath)

	// Set Thumbnail Path
	thumbnailFullPath := strings.TrimSuffix(fullPath, filepath.Ext(fullPath)) + ".jpg"
	recipe.ThumbnailPath = "videos/" + filepath.Base(thumbnailFullPath)

	// Save to Database
	if result := database.DB.Create(recipe); result.Error != nil {
		log.Printf("Error saving to database: %v", result.Error)
		return nil, fmt.Errorf("failed to save recipe: %v", result.Error)
	}

	log.Printf("Recipe saved with ID: %d", recipe.ID)
	return recipe, nil
}
