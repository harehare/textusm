package firebase

import (
	"context"

	"cloud.google.com/go/firestore"
	"github.com/harehare/textusm/internal/config"
	"github.com/harehare/textusm/internal/domain/model/gistitem"
	itemRepo "github.com/harehare/textusm/internal/domain/repository/gistitem"
	e "github.com/harehare/textusm/internal/error"
	"github.com/samber/mo"
	"google.golang.org/api/iterator"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

type FirestoreGistItemRepository struct {
	client *firestore.Client
}

func NewGistItemRepository(config *config.Config) itemRepo.GistItemRepository {
	return &FirestoreGistItemRepository{client: config.FirestoreClient}
}

func (r *FirestoreGistItemRepository) FindByID(ctx context.Context, userID string, itemID string) mo.Result[*gistitem.GistItem] {
	fields, err := r.client.Collection(usersCollection).Doc(userID).Collection(gistItemsCollection).Doc(itemID).Get(ctx)

	if st, ok := status.FromError(err); ok && st.Code() == codes.NotFound {
		return mo.Err[*gistitem.GistItem](e.NotFoundError(err))
	}

	if err != nil {
		return mo.Err[*gistitem.GistItem](e.NotFoundError(err))
	}

	return gistitem.MapToGistItem(fields.Data())
}

func (r *FirestoreGistItemRepository) Find(ctx context.Context, userID string, offset, limit int) mo.Result[[]*gistitem.GistItem] {
	var items []*gistitem.GistItem
	iter := r.client.Collection(usersCollection).Doc(userID).Collection(gistItemsCollection).OrderBy("UpdatedAt", firestore.Desc).Offset(offset).Limit(limit).Documents(ctx)

	for {
		doc, err := iter.Next()
		if err == iterator.Done {
			break
		}

		if err != nil {
			return mo.Err[[]*gistitem.GistItem](err)
		}

		ret := gistitem.MapToGistItem(doc.Data())
		if ret.IsError() {
			return mo.Err[[]*gistitem.GistItem](ret.Error())
		}

		items = append(items, ret.OrEmpty())
	}

	return mo.Ok(items)
}

func (r *FirestoreGistItemRepository) Save(ctx context.Context, userID string, item *gistitem.GistItem) mo.Result[*gistitem.GistItem] {
	_, err := r.client.Collection(usersCollection).Doc(userID).Collection(gistItemsCollection).Doc(item.ID()).Set(ctx, item.ToMap())

	if err != nil {
		return mo.Err[*gistitem.GistItem](err)
	}

	return mo.Ok(item)
}

func (r *FirestoreGistItemRepository) Delete(ctx context.Context, userID string, gistID string) mo.Result[bool] {
	_, err := r.client.Collection(usersCollection).Doc(userID).Collection(gistItemsCollection).Doc(gistID).Delete(ctx)

	if err != nil {
		return mo.Err[bool](err)
	}

	return mo.Ok(true)
}
