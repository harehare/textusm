package share

import (
	"context"

	"github.com/google/uuid"
	"github.com/harehare/textusm/internal/config"
	"github.com/harehare/textusm/internal/context/values"
	"github.com/harehare/textusm/internal/db/postgres"
	"github.com/harehare/textusm/internal/domain/model/item/diagramitem"
	"github.com/harehare/textusm/internal/domain/model/share"
	shareRepo "github.com/harehare/textusm/internal/domain/repository/share"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/samber/mo"
	"golang.org/x/crypto/bcrypt"
)

type PostgresShareRepository struct {
	_db *postgres.Queries
}

func NewPostgresShareRepository(config *config.Config) shareRepo.ShareRepository {
	return &PostgresShareRepository{_db: postgres.New(config.PostgresConn)}
}

func (r *PostgresShareRepository) tx(ctx context.Context) *postgres.Queries {
	tx := values.GetPostgresTx(ctx)

	if tx.IsPresent() {
		return r._db.WithTx(*tx.MustGet())
	} else {
		return r._db
	}
}

func (r *PostgresShareRepository) Find(ctx context.Context, hashKey string) mo.Result[shareRepo.ShareValue] {
	s, err := r.tx(ctx).GetShareCondition(ctx, hashKey)

	if err != nil {
		return mo.Err[shareRepo.ShareValue](err)
	}

	item, err := r.tx(ctx).GetItem(ctx, postgres.GetItemParams{
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

func (r *PostgresShareRepository) Save(ctx context.Context, userID, hashKey string, item *diagramitem.DiagramItem, shareInfo *share.Share) mo.Result[bool] {
	expireTime := shareInfo.ExpireTime
	id, err := uuid.Parse(item.ID())

	if err != nil {
		return mo.Err[bool](err)
	}

	_, err = r.tx(ctx).GetShareConditionItem(ctx, postgres.GetShareConditionItemParams{
		Location:  postgres.LocationSYSTEM,
		DiagramID: pgtype.UUID{Bytes: id, Valid: true},
	})

	if err == nil {
		err = r.tx(ctx).DeleteShareConditionItem(ctx, postgres.DeleteShareConditionItemParams{
			Location:  postgres.LocationSYSTEM,
			DiagramID: pgtype.UUID{Bytes: id, Valid: true},
		})

		if err != nil {
			return mo.Err[bool](err)
		}
	}

	var savePassword string

	if shareInfo.Password != "" {
		hashedPassword, err := bcrypt.GenerateFromPassword([]byte(shareInfo.Password), bcrypt.DefaultCost)

		if err != nil {
			return mo.Err[bool](err)
		}
		savePassword = string(hashedPassword)
	} else {
		savePassword = ""
	}

	err = r.tx(ctx).CreateShareCondition(ctx, postgres.CreateShareConditionParams{
		Uid:            userID,
		Hashkey:        hashKey,
		DiagramID:      pgtype.UUID{Bytes: id, Valid: true},
		Location:       postgres.LocationSYSTEM,
		AllowIpList:    shareInfo.AllowIPList,
		AllowEmailList: shareInfo.AllowEmailList,
		ExpireTime:     &expireTime,
		Password:       &savePassword,
		Token:          shareInfo.Token,
	})

	if err != nil {
		return mo.Err[bool](err)
	}

	return mo.Ok(true)
}

func (r *PostgresShareRepository) Delete(ctx context.Context, userID, hashKey string) mo.Result[bool] {
	err := r.tx(ctx).DeleteShareCondition(ctx, hashKey)

	if err != nil {
		return mo.Err[bool](err)
	}

	return mo.Ok(true)
}
