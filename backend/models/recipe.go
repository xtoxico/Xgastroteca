package models

import (
	"xgastroteca/utils"

	"gorm.io/gorm"
)

// --- DTOs for AI Response ---

type IngredientDTO struct {
	Item     string `json:"item"`
	Quantity string `json:"quantity"`
}

// AIRecipeDTO maps perfectly to the Gemini JSON response
type AIRecipeDTO struct {
	Title       string          `json:"title"`
	Description string          `json:"description"`
	Ingredients []IngredientDTO `json:"ingredients"`
	Steps       []string        `json:"steps"`
	Tags        []string        `json:"tags"`
	CookingTime string          `json:"cooking_time"`
	Error       string          `json:"error,omitempty"`
}

// --- GORM Database Models ---

type Recipe struct {
	gorm.Model
	LocalVideoPath string
	ThumbnailPath  string // Path to local thumbnail file (e.g. videos/video_123.jpg)
	Title          string
	Description    string
	CookingTime    string
	VideoFileID    string // Internal or Gemini file ID if needed

	// Composite Unique Index for Multi-Platform Support
	Source     string `gorm:"uniqueIndex:idx_source_id"` // instagram, youtube, tiktok
	ExternalID string `gorm:"uniqueIndex:idx_source_id"`

	// Relations
	Ingredients []Ingredient `gorm:"foreignKey:RecipeID"`
	Steps       []Step       `gorm:"foreignKey:RecipeID"`
	Tags        []Tag        `gorm:"foreignKey:RecipeID"`

	// Search Optimization
	SearchText string `json:"-" gorm:"index"`
}

// BeforeSave hook to populate SearchText
func (r *Recipe) BeforeSave(tx *gorm.DB) (err error) {
	r.SearchText = utils.NormalizeString(r.Title + " " + r.Description)
	return
}

type Ingredient struct {
	gorm.Model
	RecipeID uint
	Item     string
	Quantity string
}

type Step struct {
	gorm.Model
	RecipeID uint
	Text     string
}

type Tag struct {
	gorm.Model
	RecipeID uint
	Name     string
}
