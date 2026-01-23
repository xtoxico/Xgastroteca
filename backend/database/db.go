package database

import (
	"log"
	"xgastroteca/models"

	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

var DB *gorm.DB

func InitDB() {
	var err error
	// The volume is mapped to /app/data, so we save the DB there to persist it
	DB, err = gorm.Open(sqlite.Open("./data/recipes.db"), &gorm.Config{})
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}

	// Auto Migrate the schema
	log.Println("Migrating database schema...")
	err = DB.AutoMigrate(
		&models.Recipe{},
		&models.Ingredient{},
		&models.Step{},
		&models.Tag{},
		&models.ProcessingJob{},
	)
	if err != nil {
		log.Fatal("Failed to migrate database:", err)
	}
	log.Println("Database migration completed.")
}
