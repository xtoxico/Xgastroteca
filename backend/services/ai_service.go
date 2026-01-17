package services

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"time"
	"xgastroteca/models"

	"github.com/google/generative-ai-go/genai"
	"google.golang.org/api/option"
)

// AnalyzeVideo uploads a video to Gemini and extracts a recipe from it.
func AnalyzeVideo(videoPath string) (*models.Recipe, error) {
	ctx := context.Background()
	apiKey := os.Getenv("GEMINI_API_KEY")
	if apiKey == "" {
		return nil, fmt.Errorf("GEMINI_API_KEY environment variable not set")
	}

	client, err := genai.NewClient(ctx, option.WithAPIKey(apiKey))
	if err != nil {
		return nil, fmt.Errorf("failed to create Gemini client: %v", err)
	}
	defer client.Close()

	// 1. Upload the file
	log.Printf("Uploading file: %s", videoPath)
	f, err := os.Open(videoPath)
	if err != nil {
		return nil, fmt.Errorf("failed to open video file: %v", err)
	}
	defer f.Close()

	uploadResult, err := client.UploadFile(ctx, "", f, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to upload file: %v", err)
	}
	log.Printf("File uploaded. URI: %s", uploadResult.URI)

	// Ensure file is deleted after processing (optional but good practice)
	defer func() {
		log.Printf("Deleting file from cloud: %s", uploadResult.Name)
		if err := client.DeleteFile(ctx, uploadResult.Name); err != nil {
			log.Printf("Failed to delete file: %v", err)
		}
	}()

	// 2. Poll for file state
	for {
		file, err := client.GetFile(ctx, uploadResult.Name)
		if err != nil {
			return nil, fmt.Errorf("failed to get file state: %v", err)
		}

		log.Printf("File processing state: %s", file.State)

		if file.State == genai.FileStateActive {
			break
		}
		if file.State == genai.FileStateFailed {
			return nil, fmt.Errorf("file processing failed")
		}

		time.Sleep(5 * time.Second)
	}

	// 3. Generate content
	model := client.GenerativeModel("gemini-2.5-flash")
	model.ResponseMIMEType = "application/json" // Force JSON response

	prompt := "Eres un chef experto. Analiza el video y extrae la receta en formato JSON. Incluye: title, description, ingredients (lista de objetos con campos 'item' y 'quantity'), steps, tags y cooking_time. IMPORTANTE: Si el video NO es claramente sobre preparación de alimentos o una receta (ej: es un baile, un vlog sin cocina, un meme), devuelve un JSON ÚNICAMENTE con el campo: {\"error\": \"not_a_recipe\"}. Responde SOLO con el JSON limpio, sin bloques de código markdown."

	// Pass the file URI directly if the client supports it via Part mechanism
	// or retrieve the file object again if needed, but GenAI-Go usually takes the URIPart or FileData
	// The standard way in the official library for a File uploaded via File API is to use FileData with the file URI.

	resp, err := model.GenerateContent(ctx, genai.Text(prompt), genai.FileData{URI: uploadResult.URI})
	if err != nil {
		return nil, fmt.Errorf("failed to generate content: %v", err)
	}

	if len(resp.Candidates) == 0 || len(resp.Candidates[0].Content.Parts) == 0 {
		return nil, fmt.Errorf("no content generated")
	}

	// 4. Parse response into DTO
	var jsonText string
	for _, part := range resp.Candidates[0].Content.Parts {
		if txt, ok := part.(genai.Text); ok {
			jsonText += string(txt)
		}
	}

	log.Printf("Gemini Response: %s", jsonText)

	var dto models.AIRecipeDTO
	if err := json.Unmarshal([]byte(jsonText), &dto); err != nil {
		return nil, fmt.Errorf("failed to parse JSON response: %v \nRaw text: %s", err, jsonText)
	}

	if dto.Error == "not_a_recipe" {
		return nil, fmt.Errorf("not_a_recipe")
	}

	// 5. Convert DTO to GORM Model
	recipe := &models.Recipe{
		Title:          dto.Title,
		Description:    dto.Description,
		CookingTime:    dto.CookingTime,
		LocalVideoPath: videoPath,
		VideoFileID:    uploadResult.Name,
	}

	// Map Ingredients
	for _, ing := range dto.Ingredients {
		recipe.Ingredients = append(recipe.Ingredients, models.Ingredient{
			Item:     ing.Item,
			Quantity: ing.Quantity,
		})
	}

	// Map Steps
	for _, stepText := range dto.Steps {
		recipe.Steps = append(recipe.Steps, models.Step{
			Text: stepText,
		})
	}

	// Map Tags
	for _, tagName := range dto.Tags {
		recipe.Tags = append(recipe.Tags, models.Tag{
			Name: tagName,
		})
	}

	return recipe, nil
}
