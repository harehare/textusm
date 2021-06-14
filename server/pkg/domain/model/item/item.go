package item

import (
	"time"

	"github.com/harehare/textusm/pkg/domain/values"
)

type Item struct {
	ID         values.ItemID  `json:"id"`
	Title      string         `json:"title"`
	Text       string         `json:"text"`
	Thumbnail  *string        `json:"thumbnail"`
	Diagram    values.Diagram `json:"diagram"`
	IsPublic   bool           `json:"isPublic"`
	IsBookmark bool           `json:"isBookmark"`
	Tags       []*string      `json:"tags"`
	CreatedAt  time.Time      `json:"createdAt"`
	UpdatedAt  time.Time      `json:"updatedAt"`
}
