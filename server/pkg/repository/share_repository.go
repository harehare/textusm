package repository

import (
	"context"

	"github.com/harehare/textusm/pkg/item"
)

type ShareRepository interface {
	Find(ctx context.Context, hashKey string) (*item.Item, *string, error)
	Save(ctx context.Context, hashKey string, item *item.Item, password *string) error
	Delete(ctx context.Context, hashKey string) error
}
