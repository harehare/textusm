package item

import (
	"context"

	"cloud.google.com/go/firestore"
	"github.com/harehare/textusm/pkg/context/values"
	itemModel "github.com/harehare/textusm/pkg/domain/model/item"
	itemRepo "github.com/harehare/textusm/pkg/domain/repository/item"
	v "github.com/harehare/textusm/pkg/domain/values"
	e "github.com/harehare/textusm/pkg/error"
	uuid "github.com/satori/go.uuid"
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

func (r *FirestoreItemRepository) FindByID(ctx context.Context, userID string, itemID v.ItemID, isPublic bool) (*itemModel.Item, error) {
	var (
		fields *firestore.DocumentSnapshot
		err    error
	)
	if isPublic {
		fields, err = r.client.Collection(publicCollection).Doc(itemID.String()).Get(ctx)
	} else {
		fields, err = r.client.Collection(usersCollection).Doc(userID).Collection(itemsCollection).Doc(itemID.String()).Get(ctx)
	}

	if st, ok := status.FromError(err); ok && st.Code() == codes.NotFound {
		return nil, e.NotFoundError(err)
	}

	if err != nil {
		return nil, err
	}

	var i itemModel.Item
	if err := fields.DataTo(&i); err != nil {
		return nil, err
	}

	return &i, nil
}

func (r *FirestoreItemRepository) Find(ctx context.Context, userID string, offset, limit int, isPublic bool) ([]*itemModel.Item, error) {
	var (
		items []*itemModel.Item
		iter  *firestore.DocumentIterator
	)
	if isPublic {
		iter = r.client.Collection(publicCollection).OrderBy("UpdatedAt", firestore.Desc).Offset(offset).Limit(limit).Documents(ctx)
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

		var i itemModel.Item
		if err := doc.DataTo(&i); err != nil {
			return nil, err
		}

		items = append(items, &i)
	}

	return items, nil
}

func (r *FirestoreItemRepository) Save(ctx context.Context, userID string, item *itemModel.Item, isPublic bool) (*itemModel.Item, error) {
	if item.ID == "" {
		item.ID = v.NewItemID(uuid.NewV4().String())
	}

	var err error

	if isPublic {
		_, err = r.client.Collection(publicCollection).Doc(item.ID.String()).Set(ctx, item)
	} else {
		_, err = r.client.Collection(usersCollection).Doc(userID).Collection(itemsCollection).Doc(item.ID.String()).Set(ctx, item)
	}

	if err != nil {
		return nil, err
	}

	return item, nil
}

func (r *FirestoreItemRepository) Delete(ctx context.Context, userID string, itemID v.ItemID, isPublic bool) error {
	tx := values.GetTx(ctx)

	if tx == nil {
		if isPublic {
			_, err := r.client.Collection(publicCollection).Doc(itemID.String()).Delete(ctx)
			return err
		} else {
			_, err := r.client.Collection(usersCollection).Doc(userID).Collection(itemsCollection).Doc(itemID.String()).Delete(ctx)
			return err
		}
	}

	if isPublic {
		ref := r.client.Collection(publicCollection).Doc(itemID.String())
		return tx.Delete(ref)
	} else {
		ref := r.client.Collection(usersCollection).Doc(userID).Collection(itemsCollection).Doc(itemID.String())
		return tx.Delete(ref)
	}
}
