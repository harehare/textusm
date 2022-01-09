package item

import (
	"os"
	"time"

	"github.com/harehare/textusm/pkg/domain/values"
	e "github.com/harehare/textusm/pkg/error"
	"github.com/harehare/textusm/pkg/util"
)

var (
	encryptKey = []byte(os.Getenv("ENCRYPT_KEY"))
)

type DiagramItemBuilder interface {
	WithID(ID string) DiagramItemBuilder
	WithTitle(title string) DiagramItemBuilder
	WithEncryptedText(text string) DiagramItemBuilder
	WithPlainText(text string) DiagramItemBuilder
	WithThumbnail(thumbnail string) DiagramItemBuilder
	WithDiagram(diagram string) DiagramItemBuilder
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
	b.id = id
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

func (b *builder) WithThumbnail(thumbnail string) DiagramItemBuilder {
	b.thumbnail = &thumbnail
	return b
}

func (b *builder) WithDiagram(diagram string) DiagramItemBuilder {
	var d interface{} = diagram
	b.diagram = d.(values.Diagram)
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
