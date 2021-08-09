package item

import (
	"context"

	m "github.com/harehare/textusm/pkg/domain/model/item"
	"github.com/harehare/textusm/pkg/domain/values"
)

type GistItemRepository interface {
	FindByID(ctx context.Context, userID string, gistID values.GistID) (*m.GistItem, error)
	Find(ctx context.Context, userID string, offset, limit int) ([]*m.GistItem, error)
	Save(ctx context.Context, userID string, item *m.GistItem) (*m.GistItem, error)
	Delete(ctx context.Context, userID string, itemID values.GistID) error
	RevokeToken(ctx context.Context, clientID, clientSecret, accessToken string) error
}
