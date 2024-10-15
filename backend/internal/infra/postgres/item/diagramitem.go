package item

import (
	"context"
	"database/sql"

	"github.com/google/uuid"
	"github.com/harehare/textusm/internal/config"
	"github.com/harehare/textusm/internal/context/values"
	"github.com/harehare/textusm/internal/db"
	"github.com/harehare/textusm/internal/domain/model/item/diagramitem"
	itemRepo "github.com/harehare/textusm/internal/domain/repository/item"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/samber/mo"
)

type PostgresItemRepository struct {
	db *db.Queries
}

func NewPostgresItemRepository(config *config.Config) itemRepo.ItemRepository {
	return &PostgresItemRepository{db: db.New(config.DBConn)}
}

func (r *PostgresItemRepository) FindByID(ctx context.Context, userID string, itemID string, isPublic bool) mo.Result[*diagramitem.DiagramItem] {
	u, err := uuid.Parse(itemID)

	if err != nil {
		return mo.Err[*diagramitem.DiagramItem](err)
	}

	i, err := r.db.GetItem(ctx, db.GetItemParams{
		Uid:       userID,
		DiagramID: pgtype.UUID{Bytes: u, Valid: true},
	})

	if err != nil {
		return mo.Err[*diagramitem.DiagramItem](err)
	}

	var thumbnail mo.Option[string]

	if i.Thumbnail == nil {
		thumbnail = mo.None[string]()
	} else {
		thumbnail = mo.Some[string](*i.Thumbnail)
	}

	id, err := i.DiagramID.Value()

	if err != nil {
		return mo.Err[*diagramitem.DiagramItem](err)
	}

	return diagramitem.New().
		WithID(id.(string)).
		WithTitle(*i.Title).
		WithEncryptedText(i.Text).
		WithThumbnail(thumbnail).
		WithDiagramString(string(i.Diagram)).
		WithIsPublic(*i.IsPublic).
		WithIsBookmark(*i.IsBookmark).
		WithCreatedAt(i.CreatedAt.Time).
		WithUpdatedAt(i.UpdatedAt.Time).
		Build()
}

func (r *PostgresItemRepository) Find(ctx context.Context, userID string, offset, limit int, isPublic bool, isBookmark bool, shouldLoadText bool) mo.Result[[]*diagramitem.DiagramItem] {
	dbItems, err := r.db.ListItems(ctx, db.ListItemsParams{
		Uid:        userID,
		IsPublic:   &isPublic,
		IsBookmark: &isBookmark,
		Limit:      int32(limit),
		Offset:     int32(offset),
	})

	if err != nil {
		return mo.Err[[]*diagramitem.DiagramItem](err)
	}

	var items []*diagramitem.DiagramItem

	for _, i := range dbItems {
		var thumbnail mo.Option[string]

		if i.Thumbnail == nil {
			thumbnail = mo.None[string]()
		} else {
			thumbnail = mo.Some[string](*i.Thumbnail)
		}

		id, err := i.DiagramID.Value()

		if err != nil {
			return mo.Err[[]*diagramitem.DiagramItem](err)
		}

		item := diagramitem.New().
			WithID(id.(string)).
			WithTitle(*i.Title).
			WithEncryptedText(i.Text).
			WithThumbnail(thumbnail).
			WithDiagramString(string(i.Diagram)).
			WithIsPublic(*i.IsPublic).
			WithIsBookmark(*i.IsBookmark).
			WithCreatedAt(i.CreatedAt.Time).
			WithUpdatedAt(i.UpdatedAt.Time).
			Build()

		if item.IsError() {
			return mo.Err[[]*diagramitem.DiagramItem](item.Error())
		}

		items = append(items, item.MustGet())
	}

	return mo.Ok(items)
}

func (r *PostgresItemRepository) Save(ctx context.Context, userID string, item *diagramitem.DiagramItem, isPublic bool) mo.Result[*diagramitem.DiagramItem] {
	u, err := uuid.Parse(item.ID())

	if err != nil {
		return mo.Err[*diagramitem.DiagramItem](err)
	}

	_, err = r.db.GetItem(ctx, db.GetItemParams{
		Uid:       userID,
		DiagramID: pgtype.UUID{Bytes: u, Valid: true},
	})

	isBookmark := item.IsBookmark()
	title := item.Title()

	isBookmarkPtr := &isBookmark
	isPublicPtr := &isPublic
	titlePtr := &title

	if err == sql.ErrNoRows {
		r.db.CreateItem(ctx, db.CreateItemParams{
			Diagram:    db.Diagram(item.Diagram()),
			DiagramID:  pgtype.UUID{Bytes: u, Valid: true},
			IsBookmark: isBookmarkPtr,
			IsPublic:   isPublicPtr,
			Title:      titlePtr,
			Text:       item.Text(),
			Thumbnail:  item.Thumbnail(),
			Location:   db.LocationSYSTEM,
		})
	} else if err != nil {
		return mo.Err[*diagramitem.DiagramItem](err)
	} else {
		r.db.UpdateItem(ctx, db.UpdateItemParams{
			Diagram:    db.Diagram(item.Diagram()),
			IsBookmark: isBookmarkPtr,
			IsPublic:   isPublicPtr,
			Title:      &title,
			Text:       item.Text(),
			Thumbnail:  item.Thumbnail(),
			Uid:        userID,
			DiagramID:  pgtype.UUID{Bytes: u, Valid: true},
			Location:   db.LocationSYSTEM,
		})
	}
	return mo.Ok(item)
}

func (r *PostgresItemRepository) Delete(ctx context.Context, userID string, itemID string, isPublic bool) mo.Result[bool] {
	var dbWithTx *db.Queries

	tx := values.GetDBTx(ctx)

	if tx.IsPresent() {
		dbWithTx = r.db.WithTx(*tx.MustGet())
	} else {
		dbWithTx = r.db
	}

	u, err := uuid.Parse(itemID)

	if err != nil {
		return mo.Err[bool](err)
	}

	dbWithTx.DeleteItem(ctx, db.DeleteItemParams{
		Uid:       userID,
		DiagramID: pgtype.UUID{Bytes: u, Valid: true},
	})

	return mo.Ok(true)
}
