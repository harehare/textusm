package server

import (
	"log"
	"os"

	"github.com/harehare/textusm/server/models"
	"github.com/harehare/textusm/server/services"
	"github.com/jinzhu/gorm"
	_ "github.com/lib/pq"
)

var db *gorm.DB

func InitDB() error {
	var err error
	databaseURL := os.Getenv("DATABASE_URL")
	db, err = gorm.Open("postgres", databaseURL)
	if err != nil {
		log.Fatal(err)
		return err
	}
	// TODO:
	db.LogMode(os.Getenv("GO_ENV") != "production")

	// TODO: migrate
	db.AutoMigrate(models.Item{})

	services.DB = db

	return nil
}
