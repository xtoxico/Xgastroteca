package models

import (
	"time"

	"gorm.io/gorm"
)

type JobStatus string

const (
	JobStatusPending    JobStatus = "PENDING"
	JobStatusProcessing JobStatus = "PROCESSING"
	JobStatusCompleted  JobStatus = "COMPLETED"
	JobStatusFailed     JobStatus = "FAILED"
)

type ProcessingJob struct {
	gorm.Model
	URL         string    `json:"url"`
	Status      JobStatus `json:"status" gorm:"default:'PENDING'"`
	RetryCount  int       `json:"retry_count" gorm:"default:0"`
	NextRetryAt time.Time `json:"next_retry_at"`
	ErrorMsg    string    `json:"error_msg"`
}
