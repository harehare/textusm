package gistitem

import (
	"errors"
	"time"

	"github.com/harehare/textusm/pkg/domain/values"
	e "github.com/harehare/textusm/pkg/error"
	"github.com/samber/mo"
	uuid "github.com/satori/go.uuid"
)

type GistItemBuilder interface {
	WithID(ID string) GistItemBuilder
	WithURL(url string) GistItemBuilder
	WithTitle(title string) GistItemBuilder
	WithThumbnail(thumbnail mo.Option[string]) GistItemBuilder
	WithDiagramString(diagram string) GistItemBuilder
	WithDiagram(diagram values.Diagram) GistItemBuilder
	WithIsBookmark(isPublic bool) GistItemBuilder
	WithCreatedAt(createdAt time.Time) GistItemBuilder
	WithUpdatedAt(updatedAt time.Time) GistItemBuilder
	Build() mo.Result[*GistItem]
}

type builder struct {
	createdAt  time.Time
	updatedAt  time.Time
	thumbnail  mo.Option[string]
	title      string
	diagram    values.Diagram
	id         string
	url        string
	errors     []error
	isBookmark bool
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

func (b *builder) WithThumbnail(thumbnail mo.Option[string]) GistItemBuilder {
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

func (b *builder) Build() mo.Result[*GistItem] {

	if len(b.errors) > 0 {
		return mo.Err[*GistItem](e.InvalidParameterError(b.errors[0]))
	}

	return mo.Ok(&GistItem{
		id:         b.id,
		url:        b.url,
		title:      b.title,
		diagram:    b.diagram,
		thumbnail:  b.thumbnail,
		isBookmark: b.isBookmark,
		createdAt:  b.createdAt,
		updatedAt:  b.updatedAt,
	})
}

type GistItem struct {
	createdAt  time.Time
	updatedAt  time.Time
	thumbnail  mo.Option[string]
	title      string
	diagram    values.Diagram
	id         string
	url        string
	isBookmark bool
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
	v := i.thumbnail.OrEmpty()
	if v == "" {
		return nil
	}
	return &v
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

func MapToGistItem(v map[string]interface{}) mo.Result[*GistItem] {
	id, ok := v["ID"].(string)

	if !ok {
		return mo.Err[*GistItem](e.InvalidParameterError(errors.New("invalid id")))
	}

	url, ok := v["URL"].(string)

	if !ok {
		return mo.Err[*GistItem](e.InvalidParameterError(errors.New("invalid url")))
	}

	title, ok := v["Title"].(string)

	if !ok {
		return mo.Err[*GistItem](e.InvalidParameterError(errors.New("invalid title")))
	}

	var thumbnail mo.Option[string]

	if v["Thumbnail"] == nil {
		thumbnail = mo.None[string]()
	} else {
		t, ok := v["Thumbnail"].(string)
		if ok {
			thumbnail = mo.Some(t)
		} else {
			thumbnail = mo.None[string]()
		}
	}

	diagram, ok := v["Diagram"].(string)

	if !ok {
		return mo.Err[*GistItem](e.InvalidParameterError(errors.New("invalid diagram")))
	}

	isBookmark, ok := v["IsBookmark"].(bool)

	if !ok {
		return mo.Err[*GistItem](e.InvalidParameterError(errors.New("invalid isBookmark")))
	}

	createdAt, ok := v["CreatedAt"].(time.Time)

	if !ok {
		return mo.Err[*GistItem](e.InvalidParameterError(errors.New("invalid createdAt")))
	}

	updatedAt, ok := v["UpdatedAt"].(time.Time)

	if !ok {
		return mo.Err[*GistItem](e.InvalidParameterError(errors.New("invalid updatedat")))
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
		"Thumbnail":  i.thumbnail.OrEmpty(),
		"Diagram":    i.diagram,
		"IsBookmark": i.isBookmark,
		"CreatedAt":  i.createdAt,
		"UpdatedAt":  i.updatedAt}
}
