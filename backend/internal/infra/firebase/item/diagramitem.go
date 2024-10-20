package item

import (
	"context"

	"cloud.google.com/go/firestore"
	"firebase.google.com/go/v4/storage"
	"github.com/harehare/textusm/internal/config"
	"github.com/harehare/textusm/internal/context/values"
	"github.com/harehare/textusm/internal/domain/model/item/diagramitem"
	itemRepo "github.com/harehare/textusm/internal/domain/repository/item"
	e "github.com/harehare/textusm/internal/error"
	"github.com/harehare/textusm/internal/infra/firebase"
	"github.com/samber/mo"
	"golang.org/x/exp/slog"
	"golang.org/x/sync/errgroup"
	"google.golang.org/api/iterator"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

const (
	itemsCollection  = "items"
	publicCollection = "public"
	usersCollection  = "users"
	storageRoot      = usersCollection
)

type FirestoreItemRepository struct {
	firestore *firestore.Client
	storage   *storage.Client
}

func NewFirestoreItemRepository(config *config.Config) itemRepo.ItemRepository {
	return &FirestoreItemRepository{firestore: config.FirestoreClient, storage: config.StorageClient}
}

func (r *FirestoreItemRepository) FindByID(ctx context.Context, userID string, itemID string, isPublic bool) mo.Result[*diagramitem.DiagramItem] {
	return r.findFromFirestore(ctx, userID, itemID, isPublic).Map(func(i *diagramitem.DiagramItem) (*diagramitem.DiagramItem, error) {
		if i.IsSaveToStorage() {
			ret := r.findFromCloudStorage(ctx, userID, itemID)
			if ret.IsError() {
				slog.Error("Failed find diagram", "userID", userID, "itemID", itemID, "isPublic", isPublic)
				return nil, ret.Error()
			}
			i.UpdateEncryptedText(ret.OrEmpty())
		}

		return i, nil
	})
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

		items = append(items, i.Map(func(v *diagramitem.DiagramItem) (*diagramitem.DiagramItem, error) {
			if shouldLoadText && v.IsSaveToStorage() {
				ret := r.findFromCloudStorage(ctx, userID, v.ID())
				if ret.IsError() {
					slog.Error("Failed find diagram", "userID", userID, "itemID", v.ID(), "isPublic", isPublic)
					return nil, ret.Error()
				}
				v.UpdateEncryptedText(ret.OrEmpty())
				return v, nil
			} else {
				return v.ClearText(), nil
			}
		}).OrEmpty())
	}

	return mo.Ok(items)
}

func (r *FirestoreItemRepository) Save(ctx context.Context, userID string, item *diagramitem.DiagramItem, isPublic bool) mo.Result[*diagramitem.DiagramItem] {
	eg, ctx := errgroup.WithContext(ctx)

	eg.Go(func() error {
		return r.saveToFirestore(ctx, userID, item, isPublic).Error()
	})

	eg.Go(func() error {
		return r.saveToCloudStorage(ctx, userID, item).Error()
	})

	if err := eg.Wait(); err != nil {
		if item.IsNew() {
			err := r.Delete(ctx, userID, item.ID(), isPublic)
			if err.IsError() {
				slog.Error("Delete failed.", "userID", userID, "itemID", item.ID())
				return mo.Err[*diagramitem.DiagramItem](err.Error())
			}
		}

		return mo.Err[*diagramitem.DiagramItem](err)
	}

	return mo.Ok(item)
}

func (r *FirestoreItemRepository) Delete(ctx context.Context, userID string, itemID string, isPublic bool) mo.Result[bool] {
	eg, ctx := errgroup.WithContext(ctx)

	eg.Go(func() error {
		return r.deleteToFirestore(ctx, userID, itemID, isPublic).Error()
	})

	eg.Go(func() error {
		return r.deleteToCloudStorage(ctx, userID, itemID).Error()
	})

	if err := eg.Wait(); err != nil {
		slog.Error("Delete failed.", "userID", userID, "itemID", itemID)
		return mo.Err[bool](err)
	}

	return mo.Ok(true)
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

func (r *FirestoreItemRepository) findFromCloudStorage(ctx context.Context, userID string, itemID string) mo.Result[string] {
	storage := firebase.NewCloudStorage(r.storage)
	return storage.Get(ctx, storageRoot, userID, itemID)
}

func (r *FirestoreItemRepository) saveToFirestore(ctx context.Context, userID string, item *diagramitem.DiagramItem, isPublic bool) mo.Result[bool] {
	values := item.ToMap()
	delete(values, "Text")

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

func (r *FirestoreItemRepository) saveToCloudStorage(ctx context.Context, userID string, item *diagramitem.DiagramItem) mo.Result[bool] {
	text := item.EncryptedText()
	storage := firebase.NewCloudStorage(r.storage)
	return storage.Put(ctx, &text, storageRoot, userID, item.ID())
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

func (r *FirestoreItemRepository) deleteToCloudStorage(ctx context.Context, userID, itemID string) mo.Result[bool] {
	storage := firebase.NewCloudStorage(r.storage)
	return storage.Delete(ctx, storageRoot, userID, itemID)
}
