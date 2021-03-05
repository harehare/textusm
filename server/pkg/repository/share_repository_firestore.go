package repository

import (
	"context"

	"cloud.google.com/go/firestore"
	"github.com/harehare/textusm/pkg/item"
)

const (
	shareCollection = "items"
)

type FirestoreShareRepository struct {
	client *firestore.Client
}

func NewFirestoreShareRepository(client *firestore.Client) ShareRepository {
	return &FirestoreShareRepository{client: client}
}

func (r *FirestoreShareRepository) FindByID(ctx context.Context, hashKey string) (*item.Item, error) {
	fields, err := r.client.Collection(shareCollection).Doc(hashKey).Get(ctx)

	if err != nil {
		return nil, err
	}

	var i item.Item
	fields.DataTo(&i)
	return &i, nil
}

func (r *FirestoreShareRepository) Save(ctx context.Context, hashKey string, item *item.Item) error {
	_, err := r.client.Collection(shareCollection).Doc(hashKey).Set(ctx, item)
	return err
}
