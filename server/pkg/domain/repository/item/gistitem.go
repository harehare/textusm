package item

import (
	"context"

	"github.com/harehare/textusm/pkg/domain/model/item/gistitem"
	"github.com/samber/mo"
)

type GistItemRepository interface {
	FindByID(ctx context.Context, userID string, gistID string) mo.Result[*gistitem.GistItem]
	Find(ctx context.Context, userID string, offset, limit int) mo.Result[[]*gistitem.GistItem]
	Save(ctx context.Context, userID string, item *gistitem.GistItem) mo.Result[*gistitem.GistItem]
	Delete(ctx context.Context, userID string, itemID string) error
	RevokeToken(ctx context.Context, clientID, clientSecret, accessToken string) error
}
