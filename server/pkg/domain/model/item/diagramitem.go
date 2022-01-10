package item

import (
	"errors"
	"os"
	"time"

	"github.com/harehare/textusm/pkg/domain/values"
	e "github.com/harehare/textusm/pkg/error"
	"github.com/harehare/textusm/pkg/util"
	uuid "github.com/satori/go.uuid"
)

var (
	encryptKey = []byte(os.Getenv("ENCRYPT_KEY"))
)

type DiagramItemBuilder interface {
	WithID(ID string) DiagramItemBuilder
	WithTitle(title string) DiagramItemBuilder
	WithEncryptedText(text string) DiagramItemBuilder
	WithPlainText(text string) DiagramItemBuilder
	WithThumbnail(thumbnail *string) DiagramItemBuilder
	WithDiagramString(diagram string) DiagramItemBuilder
	WithDiagram(diagram values.Diagram) DiagramItemBuilder
	WithIsPublic(isPublic bool) DiagramItemBuilder
	WithIsBookmark(isPublic bool) DiagramItemBuilder
	WithCreatedAt(createdAt time.Time) DiagramItemBuilder
	WithUpdatedAt(updatedAt time.Time) DiagramItemBuilder
	Build() (*DiagramItem, error)
}

type builder struct {
	id            string
	title         string
	encryptedtext string
	thumbnail     *string
	diagram       values.Diagram
	isPublic      bool
	isBookmark    bool
	createdAt     time.Time
	updatedAt     time.Time
	errors        []error
}

func NewDiagramItem() DiagramItemBuilder {
	return &builder{}
}

func (b *builder) WithID(id string) DiagramItemBuilder {
	if id == "" {
		b.id = uuid.NewV4().String()
	} else {
		b.id = id
	}
	return b
}

func (b *builder) WithTitle(title string) DiagramItemBuilder {
	b.title = title
	return b
}

func (b *builder) WithEncryptedText(text string) DiagramItemBuilder {
	b.encryptedtext = text
	return b
}

func (b *builder) WithPlainText(text string) DiagramItemBuilder {
	t, err := encryptText(text)

	if err != nil {
		b.errors = append(b.errors, err)
		b.encryptedtext = "invalid"
	} else {
		b.encryptedtext = *t
	}

	return b
}

func (b *builder) WithThumbnail(thumbnail *string) DiagramItemBuilder {
	b.thumbnail = thumbnail
	return b
}

func (b *builder) WithDiagramString(diagram string) DiagramItemBuilder {
	b.diagram = values.Diagram(diagram)
	return b
}

func (b *builder) WithDiagram(diagram values.Diagram) DiagramItemBuilder {
	b.diagram = diagram
	return b
}

func (b *builder) WithIsPublic(isPublic bool) DiagramItemBuilder {
	b.isPublic = isPublic
	return b
}

func (b *builder) WithIsBookmark(isBookmark bool) DiagramItemBuilder {
	b.isBookmark = isBookmark
	return b
}

func (b *builder) WithCreatedAt(createdAt time.Time) DiagramItemBuilder {
	b.createdAt = createdAt
	return b
}

func (b *builder) WithUpdatedAt(updatedAt time.Time) DiagramItemBuilder {
	b.updatedAt = updatedAt
	return b
}

func (b *builder) Build() (*DiagramItem, error) {

	if len(b.errors) > 0 {
		return nil, e.InvalidParameterError(b.errors[0])
	}

	return &DiagramItem{
		id:            b.id,
		title:         b.title,
		encryptedText: b.encryptedtext,
		diagram:       b.diagram,
		thumbnail:     b.thumbnail,
		isPublic:      b.isPublic,
		isBookmark:    b.isBookmark,
		createdAt:     b.createdAt,
		updatedAt:     b.updatedAt,
	}, nil
}

type DiagramItem struct {
	id            string
	title         string
	encryptedText string
	thumbnail     *string
	diagram       values.Diagram
	isPublic      bool
	isBookmark    bool
	createdAt     time.Time
	updatedAt     time.Time
}

func (i *DiagramItem) ID() string {
	if i.id == "" {
		i.id = uuid.NewV4().String()
	}

	return i.id
}

func (i *DiagramItem) Title() string {
	return i.title
}

func (i *DiagramItem) Text() string {
	text, err := util.Decrypt(encryptKey, i.encryptedText)
	if err != nil {
		return "invalid text"
	}
	return text
}

func (i *DiagramItem) Thumbnail() *string {
	return i.thumbnail
}

func (i *DiagramItem) Diagram() values.Diagram {
	return i.diagram
}

func (i *DiagramItem) IsPublic() bool {
	return i.isPublic
}

func (i *DiagramItem) IsBookmark() bool {
	return i.isBookmark
}

func (i *DiagramItem) CreatedAt() time.Time {
	return i.createdAt
}

func (i *DiagramItem) UpdatedAt() time.Time {
	return i.updatedAt
}

func (i *DiagramItem) IsTextEmpty() bool {
	return i.encryptedText == ""
}

func (i *DiagramItem) Publish() *DiagramItem {
	i.isPublic = true
	return i
}

func (i *DiagramItem) Bookmark(isBookmark bool) *DiagramItem {
	i.isBookmark = isBookmark
	return i
}

func MapToDiagramItem(v map[string]interface{}) (*DiagramItem, error) {
	id, ok := v["ID"].(string)

	if !ok {
		return nil, e.InvalidParameterError(errors.New("invalid id"))
	}

	title, ok := v["Title"].(string)

	if !ok {
		return nil, e.InvalidParameterError(errors.New("invalid title"))
	}

	text, ok := v["Text"].(string)

	if !ok {
		return nil, e.InvalidParameterError(errors.New("invalid text"))
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

	isPublic, ok := v["IsPublic"].(bool)

	if !ok {
		return nil, e.InvalidParameterError(errors.New("invalid isPublic"))
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

	return NewDiagramItem().
		WithID(id).
		WithTitle(title).
		WithEncryptedText(text).
		WithThumbnail(thumbnail).
		WithDiagramString(diagram).
		WithIsPublic(isPublic).
		WithIsBookmark(isBookmark).
		WithCreatedAt(createdAt).
		WithUpdatedAt(updatedAt).
		Build()
}

func (i *DiagramItem) ToMap() map[string]interface{} {
	return map[string]interface{}{"ID": i.id,
		"Title":      i.title,
		"Text":       i.encryptedText,
		"Thumbnail":  i.thumbnail,
		"Diagram":    i.diagram,
		"IsPublic":   i.isPublic,
		"IsBookmark": i.isBookmark,
		"CreatedAt":  i.createdAt,
		"UpdatedAt":  i.updatedAt}
}

func encryptText(text string) (*string, error) {
	t, err := util.Encrypt(encryptKey, text)

	if err != nil {
		return nil, e.EncryptionFailedError(err)
	}

	return &t, nil
}
