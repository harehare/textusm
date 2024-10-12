package item

import (
	"context"
	"database/sql"

	"github.com/google/uuid"
	"github.com/harehare/textusm/internal/db"
	"github.com/harehare/textusm/internal/domain/model/item/diagramitem"
	itemRepo "github.com/harehare/textusm/internal/domain/repository/item"
	"github.com/samber/mo"
)

type PostgresItemRepository struct {
	db *db.Queries
}

func NewPostgresItemRepository(db *db.Queries) itemRepo.ItemRepository {
	return &PostgresItemRepository{db: db}
}

func (r *PostgresItemRepository) FindByID(ctx context.Context, userID string, itemID string, isPublic bool) mo.Result[*diagramitem.DiagramItem] {
	u, err := uuid.Parse(itemID)

	if err != nil {
		return mo.Err[*diagramitem.DiagramItem](err)
	}

	i, err := r.db.GetItem(ctx, db.GetItemParams{
		Uid:       userID,
		DiagramID: uuid.NullUUID{UUID: u, Valid: true},
	})

	if err != nil {
		return mo.Err[*diagramitem.DiagramItem](err)
	}

	var thumbnail mo.Option[string]

	if i.Thumbnail.Valid {
		thumbnail = mo.Some[string](i.Thumbnail.String)
	} else {
		thumbnail = mo.None[string]()
	}

	return diagramitem.New().
		WithID(i.DiagramID.UUID.String()).
		WithTitle(i.Title.String).
		WithEncryptedText(i.Text).
		WithThumbnail(thumbnail).
		WithDiagramString(string(i.Diagram)).
		WithIsPublic(i.IsPublic.Bool).
		WithIsBookmark(i.IsBookmark.Bool).
		WithCreatedAt(i.CreatedAt.Time).
		WithUpdatedAt(i.UpdatedAt.Time).
		Build()
}

func (r *PostgresItemRepository) Find(ctx context.Context, userID string, offset, limit int, isPublic bool, isBookmark bool, shouldLoadText bool) mo.Result[[]*diagramitem.DiagramItem] {
	dbItems, err := r.db.ListItems(ctx, db.ListItemsParams{
		Uid:        userID,
		IsPublic:   sql.NullBool{Bool: isPublic, Valid: true},
		IsBookmark: sql.NullBool{Bool: isBookmark, Valid: true},
		Limit:      int32(limit),
		Offset:     int32(offset),
	})

	if err != nil {
		return mo.Err[[]*diagramitem.DiagramItem](err)
	}

	var items []*diagramitem.DiagramItem

	for _, i := range dbItems {
		var thumbnail mo.Option[string]

		if i.Thumbnail.Valid {
			thumbnail = mo.Some[string](i.Thumbnail.String)
		} else {
			thumbnail = mo.None[string]()
		}

		item := diagramitem.New().
			WithID(i.DiagramID.UUID.String()).
			WithTitle(i.Title.String).
			WithEncryptedText(i.Text).
			WithThumbnail(thumbnail).
			WithDiagramString(string(i.Diagram)).
			WithIsPublic(i.IsPublic.Bool).
			WithIsBookmark(i.IsBookmark.Bool).
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
		DiagramID: uuid.NullUUID{UUID: u, Valid: true},
	})

	var thumbnail sql.NullString

	if item.Thumbnail() != nil {
		thumbnail = sql.NullString{String: *item.Thumbnail(), Valid: true}
	} else {
		thumbnail = sql.NullString{}
	}

	if err == sql.ErrNoRows {
		r.db.CreateItem(ctx, db.CreateItemParams{
			Diagram:    db.Diagram(item.Diagram()),
			DiagramID:  uuid.NullUUID{UUID: u, Valid: true},
			IsBookmark: sql.NullBool{Bool: item.IsBookmark(), Valid: true},
			IsPublic:   sql.NullBool{Bool: item.IsPublic(), Valid: true},
			Title:      sql.NullString{String: item.Title(), Valid: true},
			Text:       item.Text(),
			Thumbnail:  thumbnail,
		})
	} else if err != nil {
		return mo.Err[*diagramitem.DiagramItem](err)
	} else {
		r.db.UpdateItem(ctx, db.UpdateItemParams{
			Diagram:    db.Diagram(item.Diagram()),
			IsBookmark: sql.NullBool{Bool: item.IsBookmark(), Valid: true},
			IsPublic:   sql.NullBool{Bool: item.IsPublic(), Valid: true},
			Title:      sql.NullString{String: item.Title(), Valid: true},
			Text:       item.Text(),
			Thumbnail:  thumbnail,
			Uid:        userID,
			DiagramID:  uuid.NullUUID{UUID: u, Valid: true},
		})
	}
	return mo.Ok(item)
}

func (r *PostgresItemRepository) Delete(ctx context.Context, userID string, itemID string, isPublic bool) mo.Result[bool] {
	u, err := uuid.Parse(itemID)

	if err != nil {
		return mo.Err[bool](err)
	}

	r.db.DeleteItem(ctx, db.DeleteItemParams{
		Uid:       userID,
		DiagramID: uuid.NullUUID{UUID: u, Valid: true},
	})

	return mo.Ok(true)
}
