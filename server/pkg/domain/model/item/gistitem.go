package item

import (
	"time"

	"github.com/harehare/textusm/pkg/domain/values"
)

type GistItem struct {
	ID         string         `json:"id"`
	URL        string         `json:"url"`
	Title      string         `json:"title"`
	Thumbnail  *string        `json:"thumbnail"`
	Diagram    values.Diagram `json:"diagram"`
	IsBookmark bool           `json:"isBookmark"`
	Tags       []*string      `json:"tags"`
	CreatedAt  time.Time      `json:"createdAt"`
	UpdatedAt  time.Time      `json:"updatedAt"`
}
