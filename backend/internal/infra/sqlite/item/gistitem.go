package item

import (
	"context"
	"database/sql"
	"errors"

	"github.com/harehare/textusm/internal/config"
	"github.com/harehare/textusm/internal/context/values"
	"github.com/harehare/textusm/internal/db/sqlite"
	"github.com/harehare/textusm/internal/domain/model/item/gistitem"
	itemRepo "github.com/harehare/textusm/internal/domain/repository/item"
	db "github.com/harehare/textusm/internal/infra/sqlite"
	"github.com/samber/mo"
)

type SqliteGistItemRepository struct {
	_db *sqlite.Queries
}

func NewSqliteGistItemRepository(config *config.Config) itemRepo.GistItemRepository {
	return &SqliteGistItemRepository{_db: sqlite.New(config.SqlConn)}
}

func (r *SqliteGistItemRepository) tx(ctx context.Context) *sqlite.Queries {
	tx := values.GetDBTx(ctx)

	if tx.IsPresent() {
		return r._db.WithTx(tx.MustGet())
	} else {
		return r._db
	}
}

func (r *SqliteGistItemRepository) FindByID(ctx context.Context, userID string, itemID string) mo.Result[*gistitem.GistItem] {
	i, err := r.tx(ctx).GetItem(ctx, sqlite.GetItemParams{
		Uid:       userID,
		DiagramID: itemID,
		Location:  db.LocationGIST,
	})

	if err != nil {
		return mo.Err[*gistitem.GistItem](err)
	}

	var thumbnail mo.Option[string]

	if i.Thumbnail.Valid {
		thumbnail = mo.Some[string](i.Thumbnail.String)
	} else {
		thumbnail = mo.None[string]()
	}

	return gistitem.New().
		WithID(itemID).
		WithTitle(i.Title.String).
		WithThumbnail(thumbnail).
		WithDiagramString(string(i.Diagram)).
		WithIsBookmark(db.IntToBool(i.IsBookmark)).
		WithCreatedAt(db.IntToDateTime(i.CreatedAt)).
		WithUpdatedAt(db.IntToDateTime(i.UpdatedAt)).
		Build()
}

func (r *SqliteGistItemRepository) Find(ctx context.Context, userID string, offset, limit int) mo.Result[[]*gistitem.GistItem] {
	isPublic := false
	isBookmark := false
	dbItems, err := r.tx(ctx).ListItems(ctx, sqlite.ListItemsParams{
		Uid:        userID,
		IsPublic:   db.BoolToInt(isPublic),
		IsBookmark: db.BoolToInt(isBookmark),
		Location:   db.LocationGIST,
		Limit:      int64(limit),
		Offset:     int64(offset),
	})

	if err != nil {
		return mo.Err[[]*gistitem.GistItem](err)
	}

	var items []*gistitem.GistItem

	for _, i := range dbItems {
		var thumbnail mo.Option[string]

		if i.Thumbnail.Valid {
			thumbnail = mo.Some[string](i.Thumbnail.String)
		} else {
			thumbnail = mo.None[string]()
		}

		item := gistitem.New().
			WithID(i.DiagramID).
			WithTitle(i.Title.String).
			WithThumbnail(thumbnail).
			WithDiagramString(string(i.Diagram)).
			WithIsBookmark(db.IntToBool(i.IsBookmark)).
			WithCreatedAt(db.IntToDateTime(i.CreatedAt)).
			WithUpdatedAt(db.IntToDateTime(i.UpdatedAt)).
			Build()

		if item.IsError() {
			return mo.Err[[]*gistitem.GistItem](item.Error())
		}

		items = append(items, item.MustGet())
	}

	return mo.Ok(items)
}

func (r *SqliteGistItemRepository) Save(ctx context.Context, userID string, item *gistitem.GistItem) mo.Result[*gistitem.GistItem] {
	_, err := r.tx(ctx).GetItem(ctx, sqlite.GetItemParams{
		Uid:       userID,
		DiagramID: item.ID(),
		Location:  db.LocationGIST,
	})

	isBookmark := item.IsBookmark()
	title := item.Title()

	if errors.Is(err, sql.ErrNoRows) {
		r.tx(ctx).CreateItem(ctx, sqlite.CreateItemParams{
			Uid:        userID,
			Diagram:    string(item.Diagram()),
			DiagramID:  item.ID(),
			IsBookmark: db.BoolToInt(isBookmark),
			IsPublic:   db.BoolToInt(false),
			Title:      sql.NullString{String: title, Valid: true},
			Thumbnail:  db.StringToNullString(item.Thumbnail()),
			Location:   db.LocationGIST,
			CreatedAt:  db.DateTimeToInt(item.CreatedAt()),
			UpdatedAt:  db.DateTimeToInt(item.CreatedAt()),
		})
	} else if err != nil {
		return mo.Err[*gistitem.GistItem](err)
	} else {
		r.tx(ctx).UpdateItem(ctx, sqlite.UpdateItemParams{
			Uid:        userID,
			Diagram:    string(item.Diagram()),
			IsBookmark: db.BoolToInt(isBookmark),
			IsPublic:   db.BoolToInt(false),
			Title:      sql.NullString{String: title, Valid: true},
			Thumbnail:  db.StringToNullString(item.Thumbnail()),
			DiagramID:  item.ID(),
			Location:   db.LocationGIST,
			UpdatedAt:  db.DateTimeToInt(item.CreatedAt()),
		})
	}
	return mo.Ok(item)
}

func (r *SqliteGistItemRepository) Delete(ctx context.Context, userID string, gistID string) mo.Result[bool] {
	err := r.tx(ctx).DeleteItem(ctx, sqlite.DeleteItemParams{Uid: userID, DiagramID: gistID})

	if err != nil {
		return mo.Err[bool](err)
	}

	return mo.Ok(true)
}
