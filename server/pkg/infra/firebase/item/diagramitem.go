package item

import (
	"context"

	"cloud.google.com/go/firestore"
	"firebase.google.com/go/storage"
	"github.com/harehare/textusm/pkg/context/values"
	"github.com/harehare/textusm/pkg/domain/model/item/diagramitem"
	itemRepo "github.com/harehare/textusm/pkg/domain/repository/item"
	e "github.com/harehare/textusm/pkg/error"
	"github.com/harehare/textusm/pkg/infra/firebase"
	"github.com/samber/mo"
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

func NewFirestoreItemRepository(firestore *firestore.Client, storage *storage.Client) itemRepo.ItemRepository {
	return &FirestoreItemRepository{firestore: firestore, storage: storage}
}

func (r *FirestoreItemRepository) FindByID(ctx context.Context, userID string, itemID string, isPublic bool) mo.Result[*diagramitem.DiagramItem] {
	return r.findFromFirestore(ctx, userID, itemID, isPublic).Map(func(i *diagramitem.DiagramItem) (*diagramitem.DiagramItem, error) {
		if i.IsSaveToStorage() {
			ret := r.findFromCloudStorage(ctx, userID, itemID)
			if ret.IsError() {
				return nil, ret.Error()
			}
			i.UpdateEncryptedText(ret.OrEmpty())
		}

		return i, nil
	})
}

func (r *FirestoreItemRepository) Find(ctx context.Context, userID string, offset, limit int, isPublic bool, isBookmark bool) mo.Result[[]*diagramitem.DiagramItem] {
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
			return mo.Err[[]*diagramitem.DiagramItem](err)
		}

		i := diagramitem.MapToDiagramItem(doc.Data())
		if i.IsError() {
			return mo.Err[[]*diagramitem.DiagramItem](i.Error())
		}

		items = append(items, i.Map(func(v *diagramitem.DiagramItem) (*diagramitem.DiagramItem, error) {
			return v.ClearText(), nil
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
		return mo.Err[*diagramitem.DiagramItem](e.NotFoundError(err))
	}

	if err != nil {
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
		_, err := r.firestore.Collection(publicCollection).Doc(item.ID()).Set(ctx, item.ToMap())
		if err != nil {
			return mo.Err[bool](err)
		}
	} else {
		_, err := r.firestore.Collection(usersCollection).Doc(userID).Collection(itemsCollection).Doc(item.ID()).Set(ctx, item.ToMap())
		if err != nil {
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
	tx := values.GetTx(ctx)

	if tx.IsAbsent() {
		if isPublic {
			_, err := r.firestore.Collection(publicCollection).Doc(itemID).Delete(ctx)

			if err != nil {
				return mo.Err[bool](err)
			}

			return mo.Ok(true)
		} else {
			_, err := r.firestore.Collection(usersCollection).Doc(userID).Collection(itemsCollection).Doc(itemID).Delete(ctx)

			if err != nil {
				return mo.Err[bool](err)
			}

			return mo.Ok(true)
		}
	}

	if isPublic {
		ref := r.firestore.Collection(publicCollection).Doc(itemID)
		err := tx.OrEmpty().Delete(ref)

		if err != nil {
			return mo.Err[bool](err)
		}

		return mo.Ok(true)
	} else {
		ref := r.firestore.Collection(usersCollection).Doc(userID).Collection(itemsCollection).Doc(itemID)
		err := tx.OrEmpty().Delete(ref)

		if err != nil {
			return mo.Err[bool](err)
		}

		return mo.Ok(true)
	}
}

func (r *FirestoreItemRepository) deleteToCloudStorage(ctx context.Context, userID, itemID string) mo.Result[bool] {
	storage := firebase.NewCloudStorage(r.storage)
	return storage.Delete(ctx, userID, itemID)
}
