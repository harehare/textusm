package models

import (
	"time"

	"github.com/jinzhu/gorm"
	uuid "github.com/satori/go.uuid"
)

// TODO: add user model

type Item struct {
	ID          uuid.UUID `json:"id" gorm:"type:uuid;primary_key;"`
	OwnerID     string    `json:"owner_id" gorm:"index"`
	Title       string    `json:"title" gorm:"type:text;index;"`
	Text        string    `json:"text" gorm:"type:text;index;"`
	Thumbnail   string    `json:"thumbnail,omitempty" gorm:"type:text"`
	DiagramPath string    `json:"diagram_path"`
	IsPublic    bool      `json:"is_public" gorm:"index"`
	IsBookmark  bool      `json:"is_bookmark" gorm:"index"`
	CreatedAt   time.Time `json:"-" gorm:"index"`
	UpdatedAt   time.Time `json:"updated_at" gorm:"index"`
}

type ItemDto struct {
	ID          uuid.UUID `json:"id"`
	OwnerID     string    `json:"owner_id"`
	Title       string    `json:"title"`
	Text        string    `json:"text"`
	Thumbnail   string    `json:"thumbnail,omitempty"`
	DiagramPath string    `json:"diagram_path"`
	IsPublic    bool      `json:"is_public"`
	IsBookmark  bool      `json:"is_bookmark"`
	IsRemote    bool      `json:"is_remote"`
	UpdatedAt   int64     `json:"updated_at"`
}

func ItemToDto(item Item) ItemDto {
	return ItemDto{
		ID:          item.ID,
		OwnerID:     item.OwnerID,
		Title:       item.Title,
		Text:        item.Text,
		Thumbnail:   item.Thumbnail,
		DiagramPath: item.DiagramPath,
		IsPublic:    item.IsPublic,
		IsBookmark:  item.IsBookmark,
		IsRemote:    true,
		UpdatedAt:   item.UpdatedAt.Unix() * 1000,
	}
}

func (item *Item) BeforeCreate(scope *gorm.Scope) error {
	uuid := uuid.NewV4()
	return scope.SetColumn("ID", uuid)
}
