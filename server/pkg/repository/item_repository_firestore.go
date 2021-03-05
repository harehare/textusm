package repository

import (
	"context"

	"cloud.google.com/go/firestore"
	e "github.com/harehare/textusm/pkg/error"
	"github.com/harehare/textusm/pkg/item"
	uuid "github.com/satori/go.uuid"
	"google.golang.org/api/iterator"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
)

const (
	itemsCollection  = "items"
	publicCollection = "public"
	usersCollection  = "users"
)

type FirestoreItemRepository struct {
	client *firestore.Client
}

func NewFirestoreItemRepository(client *firestore.Client) ItemRepository {
	return &FirestoreItemRepository{client: client}
}

func (r *FirestoreItemRepository) FindByID(ctx context.Context, userID, itemID string, isPublic bool) (*item.Item, error) {
	var (
		fields *firestore.DocumentSnapshot
		err    error
	)
	if isPublic {
		fields, err = r.client.Collection(publicCollection).Doc(itemID).Get(ctx)
	} else {
		fields, err = r.client.Collection(usersCollection).Doc(userID).Collection(itemsCollection).Doc(itemID).Get(ctx)
	}

	if grpc.Code(err) == codes.NotFound {
		return nil, e.NotFoundError(err)
	}

	if err != nil {
		return nil, err
	}

	var i item.Item
	fields.DataTo(&i)

	return &i, nil
}

func (r *FirestoreItemRepository) Find(ctx context.Context, userID string, offset, limit int, isPublic bool) ([]*item.Item, error) {
	var (
		items []*item.Item
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

		var i item.Item
		doc.DataTo(&i)

		items = append(items, &i)
	}

	return items, nil
}

func (r *FirestoreItemRepository) Save(ctx context.Context, userID string, item *item.Item, isPublic bool) (*item.Item, error) {
	if item.ID == "" {
		uuidv4 := uuid.NewV4()
		item.ID = uuidv4.String()
	}

	var err error

	if isPublic {
		_, err = r.client.Collection(publicCollection).Doc(item.ID).Set(ctx, item)
	} else {
		_, err = r.client.Collection(usersCollection).Doc(userID).Collection(itemsCollection).Doc(item.ID).Set(ctx, item)
	}

	if err != nil {
		return nil, err
	}

	return item, nil
}

func (r *FirestoreItemRepository) Delete(ctx context.Context, userID string, itemID string, isPublic bool) (err error) {
	if isPublic {
		_, err = r.client.Collection(publicCollection).Doc(itemID).Delete(ctx)
	} else {
		_, err = r.client.Collection(usersCollection).Doc(userID).Collection(itemsCollection).Doc(itemID).Delete(ctx)
	}

	return
}
