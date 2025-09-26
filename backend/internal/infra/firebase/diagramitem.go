package firebase

import (
	"context"

	"cloud.google.com/go/firestore"
	"firebase.google.com/go/v4/storage"
	"github.com/harehare/textusm/internal/config"
	"github.com/harehare/textusm/internal/context/values"
	"github.com/harehare/textusm/internal/domain/model/diagramitem"
	itemRepo "github.com/harehare/textusm/internal/domain/repository/diagramitem"
	e "github.com/harehare/textusm/internal/error"
	"github.com/samber/mo"
	"golang.org/x/exp/slog"
	"google.golang.org/api/iterator"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

type FirestoreItemRepository struct {
	firestore *firestore.Client
	storage   *storage.Client
}

func NewItemRepository(config *config.Config) itemRepo.ItemRepository {
	return &FirestoreItemRepository{firestore: config.FirestoreClient, storage: config.StorageClient}
}

func (r *FirestoreItemRepository) FindByID(ctx context.Context, userID string, itemID string, isPublic bool) mo.Result[*diagramitem.DiagramItem] {
	return r.findFromFirestore(ctx, userID, itemID, isPublic)
}

func (r *FirestoreItemRepository) Find(ctx context.Context, userID string, offset, limit int, isPublic bool, isBookmark bool, shouldLoadText bool) mo.Result[[]*diagramitem.DiagramItem] {
	var (
		items []*diagramitem.DiagramItem
		iter  *firestore.DocumentIterator
	)
	if isPublic {
		iter = r.firestore.Collection(publicCollection).OrderBy("UpdatedAt", firestore.Desc).Offset(offset).Limit(limit).Documents(ctx)
	} else if isBookmark {
		iter = r.firestore.Collection(usersCollection).Doc(userID).Collection(itemsCollection).Where("IsBookmark", "==", isBookmark).OrderBy("UpdatedAt", firestore.Desc).Offset(offset).Limit(limit).Documents(ctx)
	} else {
		iter = r.firestore.Collection(usersCollection).Doc(userID).Collection(itemsCollection).OrderBy("UpdatedAt", firestore.Desc).Offset(offset).Limit(limit).Documents(ctx)
	}

	for {
		doc, err := iter.Next()
		if err == iterator.Done {
			break
		}

		if err != nil {
			slog.Error("Failed find diagrams", "userID", userID, "offset", offset, "limit", limit, "isPublic", isPublic, "isBookmark", isBookmark)
			return mo.Err[[]*diagramitem.DiagramItem](err)
		}

		i := diagramitem.MapToDiagramItem(doc.Data())
		if i.IsError() {
			return mo.Err[[]*diagramitem.DiagramItem](i.Error())
		}

		items = append(items, i.MustGet())
	}

	return mo.Ok(items)
}

func (r *FirestoreItemRepository) Save(ctx context.Context, userID string, item *diagramitem.DiagramItem, isPublic bool) mo.Result[*diagramitem.DiagramItem] {
	if err := r.saveToFirestore(ctx, userID, item, isPublic).Error(); err != nil {
		slog.Error("Delete failed.", "userID", userID, "itemID", item.ID())
		return mo.Err[*diagramitem.DiagramItem](err)
	}

	return mo.Ok(item)
}

func (r *FirestoreItemRepository) Delete(ctx context.Context, userID string, itemID string, isPublic bool) mo.Result[bool] {
	return r.deleteToFirestore(ctx, userID, itemID, isPublic)
}

func (r *FirestoreItemRepository) findFromFirestore(ctx context.Context, userID string, itemID string, isPublic bool) mo.Result[*diagramitem.DiagramItem] {
	var (
		fields *firestore.DocumentSnapshot
		err    error
	)
	if isPublic {
		fields, err = r.firestore.Collection(publicCollection).Doc(itemID).Get(ctx)
	} else {
		fields, err = r.firestore.Collection(usersCollection).Doc(userID).Collection(itemsCollection).Doc(itemID).Get(ctx)
	}

	if st, ok := status.FromError(err); ok && st.Code() == codes.NotFound {
		slog.Error("Diagram not found", "userID", userID, "itemID", itemID, "isPublic", isPublic)
		return mo.Err[*diagramitem.DiagramItem](e.NotFoundError(err))
	}

	if err != nil {
		slog.Error("Failed find diagram", "userID", userID, "itemID", itemID, "isPublic", isPublic)
		return mo.Err[*diagramitem.DiagramItem](err)
	}

	return diagramitem.MapToDiagramItem(fields.Data())
}

func (r *FirestoreItemRepository) saveToFirestore(ctx context.Context, userID string, item *diagramitem.DiagramItem, isPublic bool) mo.Result[bool] {
	values := item.ToMap()

	if isPublic {
		_, err := r.firestore.Collection(publicCollection).Doc(item.ID()).Set(ctx, values)
		if err != nil {
			slog.Error("Failed save firestore", "userID", userID, "itemID", item.ID(), "isPublic", isPublic)
			return mo.Err[bool](err)
		}
	} else {
		_, err := r.firestore.Collection(usersCollection).Doc(userID).Collection(itemsCollection).Doc(item.ID()).Set(ctx, values)
		if err != nil {
			slog.Error("Failed save firestore", "userID", userID, "itemID", item.ID(), "isPublic", isPublic)
			return mo.Err[bool](err)
		}
	}

	return mo.Ok(true)
}

func (r *FirestoreItemRepository) deleteToFirestore(ctx context.Context, userID string, itemID string, isPublic bool) mo.Result[bool] {
	tx := values.GetFirestoreTx(ctx)

	if tx.IsAbsent() {
		if isPublic {
			_, err := r.firestore.Collection(publicCollection).Doc(itemID).Delete(ctx)

			if err != nil {
				slog.Error("Failed delete firestore", "userID", userID, "itemID", itemID, "isPublic", isPublic)
				return mo.Err[bool](err)
			}

			return mo.Ok(true)
		} else {
			_, err := r.firestore.Collection(usersCollection).Doc(userID).Collection(itemsCollection).Doc(itemID).Delete(ctx)

			if err != nil {
				slog.Error("Failed delete firestore", "userID", userID, "itemID", itemID, "isPublic", isPublic)
				return mo.Err[bool](err)
			}

			return mo.Ok(true)
		}
	}

	if isPublic {
		ref := r.firestore.Collection(publicCollection).Doc(itemID)
		err := tx.OrEmpty().Delete(ref)

		if err != nil {
			slog.Error("Failed delete firestore", "userID", userID, "itemID", itemID, "isPublic", isPublic)
			return mo.Err[bool](err)
		}

		return mo.Ok(true)
	} else {
		ref := r.firestore.Collection(usersCollection).Doc(userID).Collection(itemsCollection).Doc(itemID)
		err := tx.OrEmpty().Delete(ref)

		if err != nil {
			slog.Error("Failed delete firestore", "userID", userID, "itemID", itemID, "isPublic", isPublic)
			return mo.Err[bool](err)
		}

		return mo.Ok(true)
	}
}
