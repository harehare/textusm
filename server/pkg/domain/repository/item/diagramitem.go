package item

import (
	"context"

	"github.com/harehare/textusm/pkg/domain/model/item/diagramitem"
	"github.com/samber/mo"
)

type ItemRepository interface {
	FindByID(ctx context.Context, userID string, itemID string, isPublic bool) mo.Result[*diagramitem.DiagramItem]
	Find(ctx context.Context, userID string, offset, limit int, isPublic bool, isBookmark bool) mo.Result[[]*diagramitem.DiagramItem]
	Save(ctx context.Context, userID string, item *diagramitem.DiagramItem, isPublic bool) mo.Result[*diagramitem.DiagramItem]
	Delete(ctx context.Context, userID string, itemID string, isPublic bool) error
}
