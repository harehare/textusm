package item

import (
	"context"

	"cloud.google.com/go/firestore"
	"github.com/harehare/textusm/pkg/context/values"
	"github.com/harehare/textusm/pkg/domain/model/item/diagramitem"
	itemRepo "github.com/harehare/textusm/pkg/domain/repository/item"
	e "github.com/harehare/textusm/pkg/error"
	"google.golang.org/api/iterator"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

const (
	itemsCollection  = "items"
	publicCollection = "public"
	usersCollection  = "users"
)

type FirestoreItemRepository struct {
	client *firestore.Client
}

func NewFirestoreItemRepository(client *firestore.Client) itemRepo.ItemRepository {
	return &FirestoreItemRepository{client: client}
}

func (r *FirestoreItemRepository) FindByID(ctx context.Context, userID string, itemID string, isPublic bool) (*diagramitem.DiagramItem, error) {
	var (
		fields *firestore.DocumentSnapshot
		err    error
	)
	if isPublic {
		fields, err = r.client.Collection(publicCollection).Doc(itemID).Get(ctx)
	} else {
		fields, err = r.client.Collection(usersCollection).Doc(userID).Collection(itemsCollection).Doc(itemID).Get(ctx)
	}

	if st, ok := status.FromError(err); ok && st.Code() == codes.NotFound {
		return nil, e.NotFoundError(err)
	}

	if err != nil {
		return nil, err
	}

	i, err := diagramitem.MapToDiagramItem(fields.Data())

	if err != nil {
		return nil, err
	}

	return i, nil
}

func (r *FirestoreItemRepository) Find(ctx context.Context, userID string, offset, limit int, isPublic bool, isBookmark bool) ([]*diagramitem.DiagramItem, error) {
	var (
		items []*diagramitem.DiagramItem
		iter  *firestore.DocumentIterator
	)
	if isPublic {
		iter = r.client.Collection(publicCollection).OrderBy("UpdatedAt", firestore.Desc).Offset(offset).Limit(limit).Documents(ctx)
	} else if isBookmark {
		iter = r.client.Collection(usersCollection).Doc(userID).Collection(itemsCollection).Where("IsBookmark", "==", isBookmark).OrderBy("UpdatedAt", firestore.Desc).Offset(offset).Limit(limit).Documents(ctx)
	} else {
		iter = r.client.Collection(usersCollection).Doc(userID).Collection(itemsCollection).OrderBy("UpdatedAt", firestore.Desc).Offset(offset).Limit(limit).Documents(ctx)
	}

	for {
		doc, err := iter.Next()
		if err == iterator.Done {
			break
		}

		if err != nil {
			return nil, err
		}

		i, err := diagramitem.MapToDiagramItem(doc.Data())
		if err != nil {
			return nil, err
		}

		items = append(items, i)
	}

	return items, nil
}

func (r *FirestoreItemRepository) Save(ctx context.Context, userID string, item *diagramitem.DiagramItem, isPublic bool) (*diagramitem.DiagramItem, error) {
	var err error

	if isPublic {
		_, err = r.client.Collection(publicCollection).Doc(item.ID()).Set(ctx, item.ToMap())
	} else {
		_, err = r.client.Collection(usersCollection).Doc(userID).Collection(itemsCollection).Doc(item.ID()).Set(ctx, item.ToMap())
	}

	if err != nil {
		return nil, err
	}

	return item, nil
}

func (r *FirestoreItemRepository) Delete(ctx context.Context, userID string, itemID string, isPublic bool) error {
	tx := values.GetTx(ctx)

	if tx == nil {
		if isPublic {
			_, err := r.client.Collection(publicCollection).Doc(itemID).Delete(ctx)
			return err
		} else {
			_, err := r.client.Collection(usersCollection).Doc(userID).Collection(itemsCollection).Doc(itemID).Delete(ctx)
			return err
		}
	}

	if isPublic {
		ref := r.client.Collection(publicCollection).Doc(itemID)
		return tx.Delete(ref)
	} else {
		ref := r.client.Collection(usersCollection).Doc(userID).Collection(itemsCollection).Doc(itemID)
		return tx.Delete(ref)
	}
}
