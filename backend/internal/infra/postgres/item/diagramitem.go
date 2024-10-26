package item

import (
	"context"
	"database/sql"
	"errors"

	"github.com/google/uuid"
	"github.com/harehare/textusm/internal/config"
	"github.com/harehare/textusm/internal/context/values"
	"github.com/harehare/textusm/internal/db/postgres"
	"github.com/harehare/textusm/internal/domain/model/item/diagramitem"
	itemRepo "github.com/harehare/textusm/internal/domain/repository/item"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/samber/mo"
)

type PostgresItemRepository struct {
	_db *postgres.Queries
}

func NewPostgresItemRepository(config *config.Config) itemRepo.ItemRepository {
	return &PostgresItemRepository{_db: postgres.New(config.PostgresConn)}
}

func (r *PostgresItemRepository) tx(ctx context.Context) *postgres.Queries {
	tx := values.GetPostgresTx(ctx)

	if tx.IsPresent() {
		return r._db.WithTx(*tx.MustGet())
	} else {
		return r._db
	}
}

func (r *PostgresItemRepository) FindByID(ctx context.Context, userID string, itemID string, isPublic bool) mo.Result[*diagramitem.DiagramItem] {
	u, err := uuid.Parse(itemID)

	if err != nil {
		return mo.Err[*diagramitem.DiagramItem](err)
	}

	i, err := r.tx(ctx).GetItem(ctx, postgres.GetItemParams{
		DiagramID: pgtype.UUID{Bytes: u, Valid: true},
		Location:  postgres.LocationSYSTEM,
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
	dbItems, err := r.tx(ctx).ListItems(ctx, postgres.ListItemsParams{
		Location:   postgres.LocationSYSTEM,
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

	_, err = r.tx(ctx).GetItem(ctx, postgres.GetItemParams{
		DiagramID: pgtype.UUID{Bytes: u, Valid: true},
		Location:  postgres.LocationSYSTEM,
	})

	isBookmark := item.IsBookmark()
	title := item.Title()

	isBookmarkPtr := &isBookmark
	isPublicPtr := &isPublic
	titlePtr := &title

	if errors.Is(err, sql.ErrNoRows) {
		err := r.tx(ctx).CreateItem(ctx, postgres.CreateItemParams{
			Uid:        userID,
			Diagram:    postgres.Diagram(item.Diagram()),
			DiagramID:  pgtype.UUID{Bytes: u, Valid: true},
			IsBookmark: isBookmarkPtr,
			IsPublic:   isPublicPtr,
			Title:      titlePtr,
			Text:       item.Text(),
			Thumbnail:  item.Thumbnail(),
			Location:   postgres.LocationSYSTEM,
		})

		if err != nil {
			return mo.Err[*diagramitem.DiagramItem](err)
		}
	} else if err != nil {
		return mo.Err[*diagramitem.DiagramItem](err)
	} else {

		err := r.tx(ctx).UpdateItem(ctx, postgres.UpdateItemParams{
			Diagram:    postgres.Diagram(item.Diagram()),
			IsBookmark: isBookmarkPtr,
			IsPublic:   isPublicPtr,
			Title:      &title,
			Text:       item.Text(),
			Thumbnail:  item.Thumbnail(),
			DiagramID:  pgtype.UUID{Bytes: u, Valid: true},
			Location:   postgres.LocationSYSTEM,
		})

		if err != nil {
			return mo.Err[*diagramitem.DiagramItem](err)
		}
	}
	return mo.Ok(item)
}

func (r *PostgresItemRepository) Delete(ctx context.Context, userID string, itemID string, isPublic bool) mo.Result[bool] {
	u, err := uuid.Parse(itemID)

	if err != nil {
		return mo.Err[bool](err)
	}

	err = r.tx(ctx).DeleteItem(ctx, pgtype.UUID{Bytes: u, Valid: true})

	if err != nil {
		return mo.Err[bool](err)
	}

	return mo.Ok(true)
}
