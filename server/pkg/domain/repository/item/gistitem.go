package item

import (
	"context"

	"github.com/harehare/textusm/pkg/domain/model/item/gistitem"
)

type GistItemRepository interface {
	FindByID(ctx context.Context, userID string, gistID string) (*gistitem.GistItem, error)
	Find(ctx context.Context, userID string, offset, limit int) ([]*gistitem.GistItem, error)
	Save(ctx context.Context, userID string, item *gistitem.GistItem) (*gistitem.GistItem, error)
	Delete(ctx context.Context, userID string, itemID string) error
	RevokeToken(ctx context.Context, clientID, clientSecret, accessToken string) error
}
