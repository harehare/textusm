package item

import (
	"bytes"
	"context"
	"fmt"
	"net/http"
	"time"

	"cloud.google.com/go/firestore"
	itemModel "github.com/harehare/textusm/pkg/domain/model/item"
	itemRepo "github.com/harehare/textusm/pkg/domain/repository/item"
	v "github.com/harehare/textusm/pkg/domain/values"
	e "github.com/harehare/textusm/pkg/error"
	"google.golang.org/api/iterator"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
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
	fields, err := r.client.Collection(usersCollection).Doc(userID).Collection(gistItemsCollection).Doc(itemID.String()).Get(ctx)

	if st, ok := status.FromError(err); ok && st.Code() == codes.NotFound {
		return nil, e.NotFoundError(err)
	}

	if err != nil {
		return nil, err
	}

	var i itemModel.GistItem
	if err := fields.DataTo(&i); err != nil {
		return nil, err
	}

	return &i, nil
}

func (r *FirestoreGistItemRepository) Find(ctx context.Context, userID string, offset, limit int) ([]*itemModel.GistItem, error) {
	var items []*itemModel.GistItem
	iter := r.client.Collection(usersCollection).Doc(userID).Collection(gistItemsCollection).OrderBy("UpdatedAt", firestore.Desc).Offset(offset).Limit(limit).Documents(ctx)

	for {
		doc, err := iter.Next()
		if err == iterator.Done {
			break
		}

		if err != nil {
			return nil, err
		}

		var i itemModel.GistItem
		if err := doc.DataTo(&i); err != nil {
			return nil, err
		}

		items = append(items, &i)
	}

	return items, nil
}

func (r *FirestoreGistItemRepository) Save(ctx context.Context, userID string, item *itemModel.GistItem) (*itemModel.GistItem, error) {
	_, err := r.client.Collection(usersCollection).Doc(userID).Collection(gistItemsCollection).Doc(item.ID.String()).Set(ctx, item)

	if err != nil {
		return nil, err
	}

	return item, nil
}

func (r *FirestoreGistItemRepository) Delete(ctx context.Context, userID string, gistID v.GistID) error {
	_, err := r.client.Collection(usersCollection).Doc(userID).Collection(gistItemsCollection).Doc(gistID.String()).Delete(ctx)
	return err
}

func (r *FirestoreGistItemRepository) RevokeToken(ctx context.Context, clientID, clientSecret, accessToken string) error {
	client := &http.Client{Timeout: time.Duration(30) * time.Second}
	body := `{"access_token":"` + accessToken + `"}`
	req, err := http.NewRequest("DELETE", fmt.Sprintf("https://api.github.com/applications/%s/token", clientID), bytes.NewBuffer([]byte(body)))
	if err != nil {
		return err
	}
	req.SetBasicAuth(clientID, clientSecret)
	req.Header.Add("Accept", "application/vnd.github.v3+json")
	res, err := client.Do(req)

	if err != nil {
		return err
	}
	defer res.Body.Close()

	return nil
}
