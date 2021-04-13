package repository

import (
	"context"

	"github.com/harehare/textusm/pkg/item"
	"github.com/harehare/textusm/pkg/model"
)

type ShareRepository interface {
	Find(ctx context.Context, hashKey string) (*item.Item, *model.Share, error)
	Save(ctx context.Context, hashKey string, item *item.Item, shareInfo *model.Share) error
	Delete(ctx context.Context, hashKey string) error
}
