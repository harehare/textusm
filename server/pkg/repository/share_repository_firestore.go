package repository

import (
	"context"

	"cloud.google.com/go/firestore"
	"github.com/harehare/textusm/pkg/item"
	"github.com/harehare/textusm/pkg/values"
	"golang.org/x/crypto/bcrypt"
)

const (
	shareCollection = "share"
)

type FirestoreShareRepository struct {
	client *firestore.Client
}

func NewFirestoreShareRepository(client *firestore.Client) ShareRepository {
	return &FirestoreShareRepository{client: client}
}

func (r *FirestoreShareRepository) Find(ctx context.Context, hashKey string) (*item.Item, *string, error) {
	fields, err := r.client.Collection(shareCollection).Doc(hashKey).Get(ctx)

	if err != nil {
		return nil, nil, err
	}

	var i item.Item

	if err := fields.DataTo(&i); err != nil {
		return nil, nil, err
	}

	p := fields.Data()["password"].(string)
	return &i, &p, nil
}

func (r *FirestoreShareRepository) Save(ctx context.Context, hashKey string, item *item.Item, password *string) error {
	var savePassword string

	if password != nil && *password != "" {
		hashedPassword, err := bcrypt.GenerateFromPassword([]byte(*password), bcrypt.DefaultCost)

		if err != nil {
			return err
		}
		savePassword = string(hashedPassword)
	} else {
		savePassword = ""
	}

	v := map[string]interface{}{
		"id":         item.ID,
		"title":      item.Title,
		"text":       item.Text,
		"thumbnail":  item.Thumbnail,
		"diagram":    item.Diagram,
		"isPublic":   item.IsPublic,
		"isBookmark": item.IsBookmark,
		"tags":       item.Tags,
		"createdAt":  item.CreatedAt,
		"updatedAt":  item.UpdatedAt,
		"password":   savePassword}
	_, err := r.client.Collection(shareCollection).Doc(hashKey).Set(ctx, v)
	return err
}

func (r *FirestoreShareRepository) Delete(ctx context.Context, hashKey string) error {
	tx := values.GetTx(ctx)

	if tx == nil {
		_, err := r.client.Collection(shareCollection).Doc(hashKey).Delete(ctx)
		return err
	}

	ref := r.client.Collection(shareCollection).Doc(hashKey)
	return tx.Delete(ref)
}
