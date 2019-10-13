package models

import (
	"encoding/json"
	"time"

	"github.com/jinzhu/gorm"
	"github.com/jinzhu/gorm/dialects/postgres"
	uuid "github.com/satori/go.uuid"
)

const (
	RoleEditor = "Editor"
	RoleViewer = "Viewer"
)

type Item struct {
	ID          uuid.UUID      `json:"id" gorm:"type:uuid;primary_key;"`
	OwnerID     string         `json:"owner_id" gorm:"index"`
	Title       string         `json:"title" gorm:"type:text;index;"`
	Text        string         `json:"text" gorm:"type:text;"`
	Thumbnail   string         `json:"thumbnail,omitempty" gorm:"type:text"`
	DiagramPath string         `json:"diagram_path"`
	IsPublic    bool           `json:"is_public" gorm:"index"`
	IsBookmark  bool           `json:"is_bookmark" gorm:"index"`
	Users       postgres.Jsonb `json:"users"`
	CreatedAt   time.Time      `json:"-" gorm:"index"`
	UpdatedAt   time.Time      `json:"updated_at" gorm:"index"`
}

type User struct {
	ID       string `json:"id,omitempty"`
	Name     string `json:"name,omitempty"`
	PhotoURL string `json:"photo_url,omitempty"`
	Mail     string `json:"mail,omitempty"`
	Role     string `json:"role,omitempty"`
}

func JsonbToUsers(p *postgres.Jsonb) (*[]User, error) {
	var users []User
	b, err := p.MarshalJSON()

	if err != nil {
		return nil, err
	}

	err = json.Unmarshal(b, &users)

	if err != nil {
		return nil, err
	}

	return &users, nil
}

func ToJSONB(u *[]User) (*postgres.Jsonb, error) {
	b, err := json.Marshal(u)

	if err != nil {
		return nil, err
	}

	return &postgres.Jsonb{json.RawMessage(string(b))}, nil
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
	Users       []User    `json:"users"`
	UpdatedAt   int64     `json:"updated_at"`
}

func ItemToDto(item Item) (*ItemDto, error) {
	users, err := JsonbToUsers(&item.Users)

	if err != nil {
		return nil, err
	}

	return &ItemDto{
		ID:          item.ID,
		OwnerID:     item.OwnerID,
		Title:       item.Title,
		Text:        item.Text,
		Thumbnail:   item.Thumbnail,
		DiagramPath: item.DiagramPath,
		IsPublic:    item.IsPublic,
		IsBookmark:  item.IsBookmark,
		IsRemote:    true,
		Users:       *users,
		UpdatedAt:   item.UpdatedAt.Unix() * 1000,
	}, nil
}

func (item *Item) BeforeCreate(scope *gorm.Scope) error {
	uuid := uuid.NewV4()
	return scope.SetColumn("ID", uuid)
}
