package services

import (
	"log"
	"time"
	"xgastroteca/database"
	"xgastroteca/models"
)

// StartQueueWorker starts a background goroutine that checks for pending jobs
func StartQueueWorker() {
	go func() {
		ticker := time.NewTicker(1 * time.Minute)
		defer ticker.Stop()

		for range ticker.C {
			processPendingJobs()
		}
	}()
}

func processPendingJobs() {
	var jobs []models.ProcessingJob

	// Find jobs that are PENDING and due for retry
	err := database.DB.Where("status = ? AND next_retry_at <= ?", models.JobStatusPending, time.Now()).Find(&jobs).Error
	if err != nil {
		log.Println("Error fetching pending jobs:", err)
		return
	}

	for _, job := range jobs {
		log.Printf("Processing queued job ID %d for URL: %s", job.ID, job.URL)

		// Update status to PROCESSING
		database.DB.Model(&job).Updates(map[string]interface{}{
			"status": models.JobStatusProcessing,
		})

		// Execute the pipeline
		// We need to call the pipeline service here.
		// Note: We need to handle the case where the pipeline is called from here.
		// Since we don't have dependency injection for the pipeline service in this simple setup,
		// we will instantiate it or call a singleton if available.
		// Looking at the structure, we probably need to invoke the same logic as the /process endpoint.

		recipe, err := ProcessVideo(job.URL)

		if err != nil {
			log.Printf("Job %d failed: %v", job.ID, err)

			// Check if it's a quota error or something permanent
			// For now, we increment retry count and schedule next retry
			// If it's a "not a recipe" error, we might want to mark as FAILED immediately.
			// But for now, we follow the generic retry logic or specific error checking if possible.

			nextRetry := time.Now().Add(15 * time.Minute)
			status := models.JobStatusPending

			// If max retries reached (e.g., 5), mark as FAILED
			if job.RetryCount >= 5 {
				status = models.JobStatusFailed
			}

			database.DB.Model(&job).Updates(map[string]interface{}{
				"status":        status,
				"retry_count":   job.RetryCount + 1,
				"next_retry_at": nextRetry,
				"error_msg":     err.Error(),
			})
		} else {
			log.Printf("Job %d completed successfully. Recipe ID: %d", job.ID, recipe.ID)
			database.DB.Model(&job).Updates(map[string]interface{}{
				"status":    models.JobStatusCompleted,
				"error_msg": "",
			})
		}
	}
}
