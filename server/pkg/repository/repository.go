package repository

import (
	"context"

	"github.com/harehare/textusm/pkg/item"
)

type Repository interface {
	FindByID(ctx context.Context, userID, itemID string) (*item.Item, error)
	Find(ctx context.Context, userID string, offset, limit int, isPublic bool) ([]*item.Item, error)
	Save(ctx context.Context, userID string, item *item.Item) (*item.Item, error)
	Delete(ctx context.Context, userID string, itemID string) error
}
