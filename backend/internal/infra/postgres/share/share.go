package share

import (
	"context"

	"github.com/google/uuid"
	"github.com/harehare/textusm/internal/config"
	"github.com/harehare/textusm/internal/context/values"
	"github.com/harehare/textusm/internal/db"
	"github.com/harehare/textusm/internal/domain/model/item/diagramitem"
	"github.com/harehare/textusm/internal/domain/model/share"
	shareRepo "github.com/harehare/textusm/internal/domain/repository/share"
	e "github.com/harehare/textusm/internal/error"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/samber/mo"
)

type PostgresShareRepository struct {
	db *db.Queries
}

func NewPostgresShareRepository(config *config.Config) shareRepo.ShareRepository {
	return &PostgresShareRepository{db: db.New(config.DBConn)}
}

func (r *PostgresShareRepository) Find(ctx context.Context, hashKey string) mo.Result[shareRepo.ShareValue] {
	s, err := r.db.GetShareCondition(ctx, hashKey)

	if err != nil {
		return mo.Err[shareRepo.ShareValue](err)
	}

	item, err := r.db.GetItem(ctx, db.GetItemParams{
		Uid:       s.Uid,
		DiagramID: s.DiagramID,
		Location:  s.Location,
	})

	if err != nil {
		return mo.Err[shareRepo.ShareValue](err)
	}

	shareInfo := share.Share{
		Token:          s.Token,
		ExpireTime:     int64(*s.ExpireTime),
		Password:       *s.Password,
		AllowIPList:    s.AllowIpList,
		AllowEmailList: s.AllowEmailList,
	}

	var thumbnail mo.Option[string]

	if item.Thumbnail == nil {
		thumbnail = mo.None[string]()
	} else {
		thumbnail = mo.Some[string](*item.Thumbnail)
	}

	id, err := item.DiagramID.Value()

	if err != nil {
		return mo.Err[shareRepo.ShareValue](err)
	}

	diagramitem := diagramitem.New().
		WithID(id.(string)).
		WithTitle(*item.Title).
		WithEncryptedText(item.Text).
		WithThumbnail(thumbnail).
		WithDiagramString(string(item.Diagram)).
		WithIsPublic(*item.IsPublic).
		WithIsBookmark(*item.IsBookmark).
		WithCreatedAt(item.CreatedAt.Time).
		WithUpdatedAt(item.UpdatedAt.Time).
		Build().OrEmpty()

	return mo.Ok(shareRepo.ShareValue{DiagramItem: diagramitem, ShareInfo: &shareInfo})
}

func (r *PostgresShareRepository) Save(ctx context.Context, hashKey string, item *diagramitem.DiagramItem, shareInfo *share.Share) mo.Result[bool] {
	userID := values.GetUID(ctx)

	if userID.IsAbsent() {
		return mo.Err[bool](e.NoAuthorizationError(e.ErrNotAuthorization))
	}

	expireTime := int32(shareInfo.ExpireTime)
	id, err := uuid.Parse(item.ID())

	if err != nil {
		return mo.Err[bool](err)
	}

	err = r.db.CreateShareCondition(ctx, db.CreateShareConditionParams{
		Hashkey:        hashKey,
		Uid:            userID.MustGet(),
		DiagramID:      pgtype.UUID{Bytes: id, Valid: true},
		Location:       db.LocationSYSTEM,
		AllowIpList:    shareInfo.AllowIPList,
		AllowEmailList: shareInfo.AllowEmailList,
		ExpireTime:     &expireTime,
		Password:       &shareInfo.Password,
		Token:          shareInfo.Token,
	})

	if err != nil {
		return mo.Err[bool](err)
	}

	return mo.Ok(true)
}

func (r *PostgresShareRepository) Delete(ctx context.Context, hashKey string) mo.Result[bool] {
	var dbWithTx *db.Queries

	tx := values.GetDBTx(ctx)

	if tx.IsPresent() {
		dbWithTx = r.db.WithTx(*tx.MustGet())
	} else {
		dbWithTx = r.db
	}

	err := dbWithTx.DeleteShareCondition(ctx, hashKey)

	if err != nil {
		return mo.Err[bool](err)
	}

	return mo.Ok(true)
}
