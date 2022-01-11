package gistitem

import (
	"errors"
	"time"

	"github.com/harehare/textusm/pkg/domain/values"
	e "github.com/harehare/textusm/pkg/error"
	uuid "github.com/satori/go.uuid"
)

type GistItemBuilder interface {
	WithID(ID string) GistItemBuilder
	WithURL(url string) GistItemBuilder
	WithTitle(title string) GistItemBuilder
	WithThumbnail(thumbnail *string) GistItemBuilder
	WithDiagramString(diagram string) GistItemBuilder
	WithDiagram(diagram values.Diagram) GistItemBuilder
	WithIsBookmark(isPublic bool) GistItemBuilder
	WithCreatedAt(createdAt time.Time) GistItemBuilder
	WithUpdatedAt(updatedAt time.Time) GistItemBuilder
	Build() (*GistItem, error)
}

type builder struct {
	id         string
	url        string
	title      string
	thumbnail  *string
	diagram    values.Diagram
	isBookmark bool
	createdAt  time.Time
	updatedAt  time.Time
	errors     []error
}

func New() GistItemBuilder {
	return &builder{}
}

func (b *builder) WithID(id string) GistItemBuilder {
	if id == "" {
		b.id = uuid.NewV4().String()
	} else {
		b.id = id
	}
	return b
}

func (b *builder) WithURL(url string) GistItemBuilder {
	b.url = url
	return b
}

func (b *builder) WithTitle(title string) GistItemBuilder {
	b.title = title
	return b
}

func (b *builder) WithThumbnail(thumbnail *string) GistItemBuilder {
	b.thumbnail = thumbnail
	return b
}

func (b *builder) WithDiagramString(diagram string) GistItemBuilder {
	b.diagram = values.Diagram(diagram)
	return b
}

func (b *builder) WithDiagram(diagram values.Diagram) GistItemBuilder {
	b.diagram = diagram
	return b
}

func (b *builder) WithIsBookmark(isBookmark bool) GistItemBuilder {
	b.isBookmark = isBookmark
	return b
}

func (b *builder) WithCreatedAt(createdAt time.Time) GistItemBuilder {
	b.createdAt = createdAt
	return b
}

func (b *builder) WithUpdatedAt(updatedAt time.Time) GistItemBuilder {
	b.updatedAt = updatedAt
	return b
}

func (b *builder) Build() (*GistItem, error) {

	if len(b.errors) > 0 {
		return nil, e.InvalidParameterError(b.errors[0])
	}

	return &GistItem{
		id:         b.id,
		url:        b.url,
		title:      b.title,
		diagram:    b.diagram,
		thumbnail:  b.thumbnail,
		isBookmark: b.isBookmark,
		createdAt:  b.createdAt,
		updatedAt:  b.updatedAt,
	}, nil
}

type GistItem struct {
	id         string
	url        string
	title      string
	thumbnail  *string
	diagram    values.Diagram
	isBookmark bool
	createdAt  time.Time
	updatedAt  time.Time
}

func (i *GistItem) ID() string {
	if i.id == "" {
		i.id = uuid.NewV4().String()
	}

	return i.id
}

func (i *GistItem) URL() string {
	return i.url
}

func (i *GistItem) Title() string {
	return i.title
}

func (i *GistItem) Thumbnail() *string {
	return i.thumbnail
}

func (i *GistItem) Diagram() values.Diagram {
	return i.diagram
}

func (i *GistItem) IsBookmark() bool {
	return i.isBookmark
}

func (i *GistItem) CreatedAt() time.Time {
	return i.createdAt
}

func (i *GistItem) UpdatedAt() time.Time {
	return i.updatedAt
}

func (i *GistItem) Bookmark(isBookmark bool) *GistItem {
	i.isBookmark = isBookmark
	return i
}

func MapToGistItem(v map[string]interface{}) (*GistItem, error) {
	id, ok := v["ID"].(string)

	if !ok {
		return nil, e.InvalidParameterError(errors.New("invalid id"))
	}

	url, ok := v["URL"].(string)

	if !ok {
		return nil, e.InvalidParameterError(errors.New("invalid url"))
	}

	title, ok := v["Title"].(string)

	if !ok {
		return nil, e.InvalidParameterError(errors.New("invalid title"))
	}

	var thumbnail *string

	if v["Thumbnail"] == nil {
		thumbnail = nil
	} else {
		t, ok := v["Thumbnail"].(string)
		if !ok {
			return nil, e.InvalidParameterError(errors.New("invalid thumbnail"))
		}
		thumbnail = &t
	}

	diagram, ok := v["Diagram"].(string)

	if !ok {
		return nil, e.InvalidParameterError(errors.New("invalid diagram"))
	}

	isBookmark, ok := v["IsBookmark"].(bool)

	if !ok {
		return nil, e.InvalidParameterError(errors.New("invalid isBookmark"))
	}

	createdAt, ok := v["CreatedAt"].(time.Time)

	if !ok {
		return nil, e.InvalidParameterError(errors.New("invalid createdAt"))
	}

	updatedAt, ok := v["UpdatedAt"].(time.Time)

	if !ok {
		return nil, e.InvalidParameterError(errors.New("invalid updatedat"))
	}

	return New().
		WithID(id).
		WithURL(url).
		WithTitle(title).
		WithThumbnail(thumbnail).
		WithDiagramString(diagram).
		WithIsBookmark(isBookmark).
		WithCreatedAt(createdAt).
		WithUpdatedAt(updatedAt).
		Build()
}

func (i *GistItem) ToMap() map[string]interface{} {
	return map[string]interface{}{"ID": i.id,
		"URL":        i.url,
		"Title":      i.title,
		"Thumbnail":  i.thumbnail,
		"Diagram":    i.diagram,
		"IsBookmark": i.isBookmark,
		"CreatedAt":  i.createdAt,
		"UpdatedAt":  i.updatedAt}
}
