package repository

import (
	"context"

	"github.com/harehare/textusm/pkg/item"
)

type ShareRepository interface {
	FindByID(ctx context.Context, hashKey string) (*item.Item, error)
	Save(ctx context.Context, hashKey string, item *item.Item) error
}
