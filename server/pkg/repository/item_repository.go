package repository

import (
	"context"

	"github.com/harehare/textusm/pkg/item"
)

type ItemRepository interface {
	FindByID(ctx context.Context, userID, itemID string, isPublic bool) (*item.Item, error)
	Find(ctx context.Context, userID string, offset, limit int, isPublic bool) ([]*item.Item, error)
	Save(ctx context.Context, userID string, item *item.Item, isPublic bool) (*item.Item, error)
	Delete(ctx context.Context, userID string, itemID string, isPublic bool) error
}
