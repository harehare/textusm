package repository

import (
	"context"
	"errors"

	"cloud.google.com/go/firestore"
	"github.com/harehare/textusm/pkg/item"
	uuid "github.com/satori/go.uuid"
	"google.golang.org/api/iterator"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
)

type FirestoreRepository struct {
	client *firestore.Client
}

func NewFirestoreRepository(client *firestore.Client) Repository {
	return &FirestoreRepository{client: client}
}

func (r *FirestoreRepository) FindByID(ctx context.Context, userID, itemID string) (*item.Item, error) {
	fields, err := r.client.Collection("users").Doc(userID).Collection("items").Doc(itemID).Get(ctx)

	if grpc.Code(err) == codes.NotFound {
		return nil, errors.New(itemID + " not found.")
	}

	if err != nil {
		return nil, err
	}

	var i item.Item
	fields.DataTo(&i)

	return &i, nil
}

func (r *FirestoreRepository) Find(ctx context.Context, userID string, offset, limit int, isPublic bool) ([]*item.Item, error) {
	var items []*item.Item
	iter := r.client.Collection("users").Doc(userID).Collection("items").OrderBy("UpdatedAt", firestore.Desc).Offset(offset).Limit(limit).Documents(ctx)

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

func (r *FirestoreRepository) Save(ctx context.Context, userID string, item *item.Item) (*item.Item, error) {
	if item.ID == "" {
		uuidv4 := uuid.NewV4()
		item.ID = uuidv4.String()
	}

	_, err := r.client.Collection("users").Doc(userID).Collection("items").Doc(item.ID).Set(ctx, item)

	if err != nil {
		return nil, err
	}

	return item, nil
}

func (r *FirestoreRepository) Delete(ctx context.Context, userID string, itemID string) error {
	_, err := r.client.Collection("users").Doc(userID).Collection("items").Doc(itemID).Delete(ctx)

	return err
}
