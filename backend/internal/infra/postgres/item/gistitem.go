package item

import (
	"context"
	"database/sql"
	"errors"

	"github.com/google/uuid"
	"github.com/harehare/textusm/internal/config"
	"github.com/harehare/textusm/internal/context/values"
	"github.com/harehare/textusm/internal/db"
	"github.com/harehare/textusm/internal/domain/model/item/gistitem"
	itemRepo "github.com/harehare/textusm/internal/domain/repository/item"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/samber/mo"
)

type PostgresGistItemRepository struct {
	_db *db.Queries
}

func NewPostgresGistItemRepository(config *config.Config) itemRepo.GistItemRepository {
	return &PostgresGistItemRepository{_db: db.New(config.PostgresConn)}
}

func (r *PostgresGistItemRepository) tx(ctx context.Context) *db.Queries {
	tx := values.GetDBTx(ctx)

	if tx.IsPresent() {
		return r._db.WithTx(*tx.MustGet())
	} else {
		return r._db
	}
}

func (r *PostgresGistItemRepository) FindByID(ctx context.Context, userID string, itemID string) mo.Result[*gistitem.GistItem] {
	u, err := uuid.Parse(itemID)

	if err != nil {
		return mo.Err[*gistitem.GistItem](err)
	}

	i, err := r.tx(ctx).GetItem(ctx, db.GetItemParams{
		DiagramID: pgtype.UUID{Bytes: u, Valid: true},
		Location:  db.LocationGIST,
	})

	if err != nil {
		return mo.Err[*gistitem.GistItem](err)
	}

	var thumbnail mo.Option[string]

	if i.Thumbnail == nil {
		thumbnail = mo.None[string]()
	} else {
		thumbnail = mo.Some[string](*i.Thumbnail)
	}

	id, err := i.DiagramID.Value()

	if err != nil {
		return mo.Err[*gistitem.GistItem](err)
	}

	return gistitem.New().
		WithID(id.(string)).
		WithTitle(*i.Title).
		WithThumbnail(thumbnail).
		WithDiagramString(string(i.Diagram)).
		WithIsBookmark(*i.IsBookmark).
		WithCreatedAt(i.CreatedAt.Time).
		WithUpdatedAt(i.UpdatedAt.Time).
		Build()
}

func (r *PostgresGistItemRepository) Find(ctx context.Context, userID string, offset, limit int) mo.Result[[]*gistitem.GistItem] {
	isPublic := false
	isBookmark := false
	dbItems, err := r.tx(ctx).ListItems(ctx, db.ListItemsParams{
		IsPublic:   &isPublic,
		IsBookmark: &isBookmark,
		Location:   db.LocationGIST,
		Limit:      int32(limit),
		Offset:     int32(offset),
	})

	if err != nil {
		return mo.Err[[]*gistitem.GistItem](err)
	}

	var items []*gistitem.GistItem

	for _, i := range dbItems {
		var thumbnail mo.Option[string]

		if i.Thumbnail == nil {
			thumbnail = mo.None[string]()
		} else {
			thumbnail = mo.Some[string](*i.Thumbnail)
		}

		id, err := i.DiagramID.Value()

		if err != nil {
			return mo.Err[[]*gistitem.GistItem](err)
		}

		item := gistitem.New().
			WithID(id.(string)).
			WithTitle(*i.Title).
			WithThumbnail(thumbnail).
			WithDiagramString(string(i.Diagram)).
			WithIsBookmark(*i.IsBookmark).
			WithCreatedAt(i.CreatedAt.Time).
			WithUpdatedAt(i.UpdatedAt.Time).
			Build()

		if item.IsError() {
			return mo.Err[[]*gistitem.GistItem](item.Error())
		}

		items = append(items, item.MustGet())
	}

	return mo.Ok(items)
}

func (r *PostgresGistItemRepository) Save(ctx context.Context, userID string, item *gistitem.GistItem) mo.Result[*gistitem.GistItem] {
	u, err := uuid.Parse(item.ID())

	if err != nil {
		return mo.Err[*gistitem.GistItem](err)
	}

	_, err = r.tx(ctx).GetItem(ctx, db.GetItemParams{
		DiagramID: pgtype.UUID{Bytes: u, Valid: true},
		Location:  db.LocationGIST,
	})

	isBookmark := item.IsBookmark()
	title := item.Title()

	isBookmarkPtr := &isBookmark
	isPublicPtr := false
	titlePtr := &title

	if errors.Is(err, sql.ErrNoRows) {
		r.tx(ctx).CreateItem(ctx, db.CreateItemParams{
			Uid:        userID,
			Diagram:    db.Diagram(item.Diagram()),
			DiagramID:  pgtype.UUID{Bytes: u, Valid: true},
			IsBookmark: isBookmarkPtr,
			IsPublic:   &isPublicPtr,
			Title:      titlePtr,
			Thumbnail:  item.Thumbnail(),
			Location:   db.LocationGIST,
		})
	} else if err != nil {
		return mo.Err[*gistitem.GistItem](err)
	} else {
		r.tx(ctx).UpdateItem(ctx, db.UpdateItemParams{
			Diagram:    db.Diagram(item.Diagram()),
			IsBookmark: isBookmarkPtr,
			IsPublic:   &isPublicPtr,
			Title:      &title,
			Thumbnail:  item.Thumbnail(),
			DiagramID:  pgtype.UUID{Bytes: u, Valid: true},
			Location:   db.LocationGIST,
		})
	}
	return mo.Ok(item)
}

func (r *PostgresGistItemRepository) Delete(ctx context.Context, userID string, gistID string) mo.Result[bool] {
	u, err := uuid.Parse(gistID)

	if err != nil {
		return mo.Err[bool](err)
	}

	err = r.tx(ctx).DeleteItem(ctx, pgtype.UUID{Bytes: u, Valid: true})

	if err != nil {
		return mo.Err[bool](err)
	}

	return mo.Ok(true)
}
