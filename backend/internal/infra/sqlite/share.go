package sqlite

import (
	"context"
	"database/sql"
	"strings"
	"time"

	"github.com/harehare/textusm/internal/config"
	"github.com/harehare/textusm/internal/context/values"
	"github.com/harehare/textusm/internal/db/sqlite"
	"github.com/harehare/textusm/internal/domain/model/diagramitem"
	"github.com/harehare/textusm/internal/domain/model/share"
	shareRepo "github.com/harehare/textusm/internal/domain/repository/share"
	"github.com/samber/mo"
	"golang.org/x/crypto/bcrypt"
)

type SqliteShareRepository struct {
	_db *sqlite.Queries
}

func NewShareRepository(config *config.Config) shareRepo.ShareRepository {
	return &SqliteShareRepository{_db: sqlite.New(config.SqlConn)}
}

func (r *SqliteShareRepository) tx(ctx context.Context) *sqlite.Queries {
	tx := values.GetDBTx(ctx)

	if tx.IsPresent() {
		return r._db.WithTx(tx.MustGet())
	} else {
		return r._db
	}
}

func (r *SqliteShareRepository) Find(ctx context.Context, hashKey string) mo.Result[shareRepo.ShareValue] {
	s, err := r.tx(ctx).GetShareCondition(ctx, hashKey)

	if err != nil {
		return mo.Err[shareRepo.ShareValue](err)
	}

	item, err := r.tx(ctx).GetItem(ctx, sqlite.GetItemParams{
		DiagramID: s.DiagramID,
		Location:  s.Location,
	})

	if err != nil {
		return mo.Err[shareRepo.ShareValue](err)
	}

	shareInfo := share.Share{
		Token:          s.Token,
		ExpireTime:     s.ExpireTime.Int64,
		Password:       s.Password.String,
		AllowIPList:    strings.Split(s.AllowIpList.String, ","),
		AllowEmailList: strings.Split(s.AllowEmailList.String, ","),
	}

	var thumbnail mo.Option[string]

	if item.Thumbnail.Valid {
		thumbnail = mo.Some[string](item.Thumbnail.String)
	} else {
		thumbnail = mo.None[string]()
	}

	diagramitem := diagramitem.New().
		WithID(item.DiagramID).
		WithTitle(item.Title.String).
		WithEncryptedText(item.Text).
		WithThumbnail(thumbnail).
		WithDiagramString(string(item.Diagram)).
		WithIsPublic(IntToBool(item.IsPublic)).
		WithIsBookmark(IntToBool(item.IsBookmark)).
		WithCreatedAt(IntToDateTime(item.CreatedAt)).
		WithUpdatedAt(IntToDateTime(item.UpdatedAt)).
		Build().OrEmpty()

	return mo.Ok(shareRepo.ShareValue{DiagramItem: diagramitem, ShareInfo: &shareInfo})
}

func (r *SqliteShareRepository) Save(ctx context.Context, userID, hashKey string, item *diagramitem.DiagramItem, shareInfo *share.Share) mo.Result[bool] {
	expireTime := shareInfo.ExpireTime
	_, err := r.tx(ctx).GetShareConditionItem(ctx, sqlite.GetShareConditionItemParams{
		Location:  LocationSYSTEM,
		DiagramID: item.ID(),
	})

	if err == nil {
		err = r.tx(ctx).DeleteShareConditionItem(ctx, sqlite.DeleteShareConditionItemParams{
			Location:  LocationSYSTEM,
			DiagramID: item.ID(),
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

	err = r.tx(ctx).CreateShareCondition(ctx, sqlite.CreateShareConditionParams{
		Uid:            userID,
		Hashkey:        hashKey,
		DiagramID:      item.ID(),
		Location:       LocationSYSTEM,
		AllowIpList:    sql.NullString{String: strings.Join(shareInfo.AllowIPList, ","), Valid: true},
		AllowEmailList: sql.NullString{String: strings.Join(shareInfo.AllowEmailList, ","), Valid: true},
		ExpireTime:     sql.NullInt64{Int64: expireTime, Valid: true},
		Password:       sql.NullString{String: savePassword, Valid: true},
		Token:          shareInfo.Token,
		CreatedAt:      DateTimeToInt(time.Now()),
		UpdatedAt:      DateTimeToInt(time.Now()),
	})

	if err != nil {
		return mo.Err[bool](err)
	}

	return mo.Ok(true)
}

func (r *SqliteShareRepository) Delete(ctx context.Context, userID, hashKey string) mo.Result[bool] {
	err := r.tx(ctx).DeleteShareCondition(ctx, hashKey)

	if err != nil {
		return mo.Err[bool](err)
	}

	return mo.Ok(true)
}
