package item

import (
	"context"

	"github.com/harehare/textusm/pkg/domain/model/item/diagramitem"
)

type ItemRepository interface {
	FindByID(ctx context.Context, userID string, itemID string, isPublic bool) (*diagramitem.DiagramItem, error)
	Find(ctx context.Context, userID string, offset, limit int, isPublic bool, isBookmark bool) ([]*diagramitem.DiagramItem, error)
	Save(ctx context.Context, userID string, item *diagramitem.DiagramItem, isPublic bool) (*diagramitem.DiagramItem, error)
	Delete(ctx context.Context, userID string, itemID string, isPublic bool) error
}
