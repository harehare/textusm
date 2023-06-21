package share

import (
	"context"

	"github.com/harehare/textusm/pkg/domain/model/item/diagramitem"
	shareModel "github.com/harehare/textusm/pkg/domain/model/share"
	"github.com/samber/mo"
)

type ShareValue struct {
	DiagramItem *diagramitem.DiagramItem
	ShareInfo   *shareModel.Share
}

type ShareRepository interface {
	Find(ctx context.Context, hashKey string) mo.Result[ShareValue]
	Save(ctx context.Context, hashKey string, item *diagramitem.DiagramItem, shareInfo *shareModel.Share) mo.Result[bool]
	Delete(ctx context.Context, hashKey string) mo.Result[bool]
}
