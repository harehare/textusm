package item

import (
	"context"
	"database/sql"

	"github.com/google/uuid"
	"github.com/harehare/textusm/internal/config"
	"github.com/harehare/textusm/internal/db"
	"github.com/harehare/textusm/internal/domain/model/item/gistitem"
	itemRepo "github.com/harehare/textusm/internal/domain/repository/item"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/samber/mo"
)

type PostgresGistItemRepository struct {
	db *db.Queries
}

func NewPostgresGistItemRepository(config *config.Config) itemRepo.GistItemRepository {
	return &PostgresGistItemRepository{db: db.New(config.DBConn)}
}

func (r *PostgresGistItemRepository) FindByID(ctx context.Context, userID string, itemID string) mo.Result[*gistitem.GistItem] {
	u, err := uuid.Parse(itemID)

	if err != nil {
		return mo.Err[*gistitem.GistItem](err)
	}

	i, err := r.db.GetItem(ctx, db.GetItemParams{
		Uid:       userID,
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
	dbItems, err := r.db.ListItems(ctx, db.ListItemsParams{
		Uid:        userID,
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

	_, err = r.db.GetItem(ctx, db.GetItemParams{
		Uid:       userID,
		DiagramID: pgtype.UUID{Bytes: u, Valid: true},
		Location:  db.LocationGIST,
	})

	isBookmark := item.IsBookmark()
	title := item.Title()

	isBookmarkPtr := &isBookmark
	isPublicPtr := false
	titlePtr := &title

	if err == sql.ErrNoRows {
		r.db.CreateItem(ctx, db.CreateItemParams{
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
		r.db.UpdateItem(ctx, db.UpdateItemParams{
			Diagram:    db.Diagram(item.Diagram()),
			IsBookmark: isBookmarkPtr,
			IsPublic:   &isPublicPtr,
			Title:      &title,
			Thumbnail:  item.Thumbnail(),
			Uid:        userID,
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

	r.db.DeleteItem(ctx, db.DeleteItemParams{
		Uid:       userID,
		DiagramID: pgtype.UUID{Bytes: u, Valid: true},
	})

	return mo.Ok(true)
}
