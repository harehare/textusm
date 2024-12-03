package sqlite

import (
	"context"
	"database/sql"
	"errors"

	"github.com/harehare/textusm/internal/config"
	"github.com/harehare/textusm/internal/context/values"
	"github.com/harehare/textusm/internal/db/sqlite"
	"github.com/harehare/textusm/internal/domain/model/gistitem"
	itemRepo "github.com/harehare/textusm/internal/domain/repository/gistitem"
	"github.com/samber/mo"
)

type SqliteGistItemRepository struct {
	_db *sqlite.Queries
}

func NewGistItemRepository(config *config.Config) itemRepo.GistItemRepository {
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
		Location:  LocationGIST,
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
		WithIsBookmark(IntToBool(i.IsBookmark)).
		WithCreatedAt(IntToDateTime(i.CreatedAt)).
		WithUpdatedAt(IntToDateTime(i.UpdatedAt)).
		Build()
}

func (r *SqliteGistItemRepository) Find(ctx context.Context, userID string, offset, limit int) mo.Result[[]*gistitem.GistItem] {
	isPublic := false
	isBookmark := false
	dbItems, err := r.tx(ctx).ListItems(ctx, sqlite.ListItemsParams{
		Uid:        userID,
		IsPublic:   BoolToInt(isPublic),
		IsBookmark: BoolToInt(isBookmark),
		Location:   LocationGIST,
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
			WithIsBookmark(IntToBool(i.IsBookmark)).
			WithCreatedAt(IntToDateTime(i.CreatedAt)).
			WithUpdatedAt(IntToDateTime(i.UpdatedAt)).
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
		Location:  LocationGIST,
	})

	isBookmark := item.IsBookmark()
	title := item.Title()

	if errors.Is(err, sql.ErrNoRows) {
		if err := r.tx(ctx).CreateItem(ctx, sqlite.CreateItemParams{
			Uid:        userID,
			Diagram:    string(item.Diagram()),
			DiagramID:  item.ID(),
			IsBookmark: BoolToInt(isBookmark),
			IsPublic:   BoolToInt(false),
			Title:      sql.NullString{String: title, Valid: true},
			Thumbnail:  StringToNullString(item.Thumbnail()),
			Location:   LocationGIST,
			CreatedAt:  DateTimeToInt(item.CreatedAt()),
			UpdatedAt:  DateTimeToInt(item.CreatedAt()),
		}); err != nil {
			return mo.Err[*gistitem.GistItem](err)
		}
	} else if err != nil {
		return mo.Err[*gistitem.GistItem](err)
	} else {
		if err := r.tx(ctx).UpdateItem(ctx, sqlite.UpdateItemParams{
			Uid:        userID,
			Diagram:    string(item.Diagram()),
			IsBookmark: BoolToInt(isBookmark),
			IsPublic:   BoolToInt(false),
			Title:      sql.NullString{String: title, Valid: true},
			Thumbnail:  StringToNullString(item.Thumbnail()),
			DiagramID:  item.ID(),
			Location:   LocationGIST,
			UpdatedAt:  DateTimeToInt(item.CreatedAt()),
		}); err != nil {
			return mo.Err[*gistitem.GistItem](err)
		}
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
