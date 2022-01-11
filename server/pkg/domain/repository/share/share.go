package share

import (
	"context"

	"github.com/harehare/textusm/pkg/domain/model/item/diagramitem"
	shareModel "github.com/harehare/textusm/pkg/domain/model/share"
)

type ShareRepository interface {
	Find(ctx context.Context, hashKey string) (*diagramitem.DiagramItem, *shareModel.Share, error)
	Save(ctx context.Context, hashKey string, item *diagramitem.DiagramItem, shareInfo *shareModel.Share) error
	Delete(ctx context.Context, hashKey string) error
}
