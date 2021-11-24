package item

import (
	"context"

	m "github.com/harehare/textusm/pkg/domain/model/item"
)

type ItemRepository interface {
	FindByID(ctx context.Context, userID string, itemID string, isPublic bool) (*m.Item, error)
	Find(ctx context.Context, userID string, offset, limit int, isPublic bool, isBookmark bool) ([]*m.Item, error)
	Save(ctx context.Context, userID string, item *m.Item, isPublic bool) (*m.Item, error)
	Delete(ctx context.Context, userID string, itemID string, isPublic bool) error
}
