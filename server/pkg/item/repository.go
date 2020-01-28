package item

import (
	"context"
)

type Repository interface {
	FindByID(ctx context.Context, userID, itemID string) (*Item, error)
	Find(ctx context.Context, userID string, offset, limit int, isBookmark, isPublic bool) ([]*Item, error)
	Save(ctx context.Context, userID string, item *Item) (*Item, error)
	Delete(ctx context.Context, userID string, itemID string) error
}
