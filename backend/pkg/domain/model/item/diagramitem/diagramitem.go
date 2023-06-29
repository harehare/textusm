package diagramitem

import (
	"errors"
	"os"
	"time"

	"github.com/harehare/textusm/pkg/domain/values"
	e "github.com/harehare/textusm/pkg/error"
	"github.com/harehare/textusm/pkg/util"
	"github.com/samber/mo"
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
	WithThumbnail(thumbnail mo.Option[string]) DiagramItemBuilder
	WithDiagramString(diagram string) DiagramItemBuilder
	WithDiagram(diagram values.Diagram) DiagramItemBuilder
	WithIsPublic(isPublic bool) DiagramItemBuilder
	WithIsBookmark(isPublic bool) DiagramItemBuilder
	WithCreatedAt(createdAt time.Time) DiagramItemBuilder
	WithUpdatedAt(updatedAt time.Time) DiagramItemBuilder
	Build() mo.Result[*DiagramItem]
}

type builder struct {
	createdAt     time.Time
	updatedAt     time.Time
	thumbnail     mo.Option[string]
	id            string
	diagram       values.Diagram
	title         string
	encryptedText string
	errors        error
	isPublic      bool
	isBookmark    bool
	isNew         bool
}

func New() DiagramItemBuilder {
	return &builder{}
}

func (b *builder) WithID(id string) DiagramItemBuilder {
	if id == "" {
		b.id = uuid.NewV4().String()
		b.isNew = true
	} else {
		b.id = id
		b.isNew = false
	}
	return b
}

func (b *builder) WithTitle(title string) DiagramItemBuilder {
	b.title = title
	return b
}

func (b *builder) WithEncryptedText(text string) DiagramItemBuilder {
	b.encryptedText = text
	return b
}

func (b *builder) WithPlainText(text string) DiagramItemBuilder {
	t, err := encryptText(text)

	if err != nil {
		if b.errors == nil {
			b.errors = err
		} else {
			b.errors = errors.Join(b.errors, err)
		}
		b.encryptedText = "invalid"
	} else {
		b.encryptedText = *t
	}

	return b
}

func (b *builder) WithThumbnail(thumbnail mo.Option[string]) DiagramItemBuilder {
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

func (b *builder) Build() mo.Result[*DiagramItem] {

	if b.errors != nil {
		return mo.Err[*DiagramItem](e.InvalidParameterError(b.errors))
	}

	return mo.Ok(&DiagramItem{
		id:            b.id,
		title:         b.title,
		encryptedText: b.encryptedText,
		diagram:       b.diagram,
		thumbnail:     b.thumbnail,
		isPublic:      b.isPublic,
		isBookmark:    b.isBookmark,
		createdAt:     b.createdAt,
		updatedAt:     b.updatedAt,
		isNew:         b.isNew,
	})
}

type DiagramItem struct {
	createdAt     time.Time
	updatedAt     time.Time
	thumbnail     mo.Option[string]
	id            string
	diagram       values.Diagram
	title         string
	encryptedText string
	isPublic      bool
	isBookmark    bool
	saveToStorage bool
	isNew         bool
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

func (i *DiagramItem) EncryptedText() string {
	return i.encryptedText
}

func (i *DiagramItem) UpdateEncryptedText(encryptedText string) *DiagramItem {
	i.encryptedText = encryptedText
	return i
}

func (i *DiagramItem) Thumbnail() *string {
	v := i.thumbnail.OrEmpty()
	if v == "" {
		return nil
	}
	return &v
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

func (i *DiagramItem) IsNew() bool {
	return i.isNew
}

func MapToDiagramItem(v map[string]interface{}) mo.Result[*DiagramItem] {
	id, ok := v["ID"].(string)

	if !ok {
		return mo.Err[*DiagramItem](e.InvalidParameterError(errors.New("invalid id")))
	}

	title, ok := v["Title"].(string)

	if !ok {
		return mo.Err[*DiagramItem](e.InvalidParameterError(errors.New("invalid title")))
	}

	text, ok := v["Text"].(string)

	if !ok {
		text = ""
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
		return mo.Err[*DiagramItem](e.InvalidParameterError(errors.New("invalid diagram")))
	}

	isPublic, ok := v["IsPublic"].(bool)

	if !ok {
		return mo.Err[*DiagramItem](e.InvalidParameterError(errors.New("invalid isPublic")))
	}

	isBookmark, ok := v["IsBookmark"].(bool)

	if !ok {
		return mo.Err[*DiagramItem](e.InvalidParameterError(errors.New("invalid isBookmark")))
	}

	createdAt, ok := v["CreatedAt"].(time.Time)

	if !ok {
		return mo.Err[*DiagramItem](e.InvalidParameterError(errors.New("invalid createdAt")))
	}

	updatedAt, ok := v["UpdatedAt"].(time.Time)

	if !ok {
		return mo.Err[*DiagramItem](e.InvalidParameterError(errors.New("invalid updatedat")))
	}

	saveToStorage, ok := v["SaveToStorage"].(bool)

	if !ok {
		saveToStorage = false
	}

	item := New().
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

	return item.Map(func(i *DiagramItem) (*DiagramItem, error) {
		i.saveToStorage = saveToStorage
		return i, nil
	})
}

func (i *DiagramItem) ClearText() *DiagramItem {
	i.encryptedText = ""
	return i
}

func (i *DiagramItem) IsSaveToStorage() bool {
	return i.saveToStorage
}

func (i *DiagramItem) ToMap() map[string]interface{} {
	return map[string]interface{}{"ID": i.id,
		"Title":         i.title,
		"Text":          i.encryptedText,
		"Thumbnail":     i.thumbnail.OrEmpty(),
		"Diagram":       i.diagram,
		"IsPublic":      i.isPublic,
		"IsBookmark":    i.isBookmark,
		"CreatedAt":     i.createdAt,
		"UpdatedAt":     i.updatedAt,
		"SaveToStorage": true}
}

func encryptText(text string) (*string, error) {
	t, err := util.Encrypt(encryptKey, text)

	if err != nil {
		return nil, e.EncryptionFailedError(err)
	}

	return &t, nil
}
