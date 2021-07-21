package item

import (
	"context"

	"cloud.google.com/go/firestore"
	itemModel "github.com/harehare/textusm/pkg/domain/model/item"
	itemRepo "github.com/harehare/textusm/pkg/domain/repository/item"
	v "github.com/harehare/textusm/pkg/domain/values"
)

const (
	gistItemsCollection = "gistitems"
)

type FirestoreGistItemRepository struct {
	client *firestore.Client
}

func NewFirestoreGistItemRepository(client *firestore.Client) itemRepo.GistItemRepository {
	return &FirestoreGistItemRepository{client: client}
}

func (r *FirestoreGistItemRepository) FindByID(ctx context.Context, userID string, itemID v.GistID) (*itemModel.GistItem, error) {
	panic("not implemented")
}

func (r *FirestoreGistItemRepository) Find(ctx context.Context, userID string, offset, limit int) ([]*itemModel.GistItem, error) {
	panic("not implemented")
}

func (r *FirestoreGistItemRepository) Save(ctx context.Context, userID string, item *itemModel.GistItem) (*itemModel.GistItem, error) {
	panic("not implemented")
}

func (r *FirestoreGistItemRepository) Delete(ctx context.Context, userID string, gistID v.GistID) error {
	panic("not implemented")
}
