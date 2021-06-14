//go:generate go run github.com/99designs/gqlgen
package server

// THIS CODE IS A STARTING POINT ONLY. IT WILL NOT BE UPDATED WITH SCHEMA CHANGES.

import (
	"context"
	"time"

	"cloud.google.com/go/firestore"
	"github.com/harehare/textusm/pkg/context/values"
	itemModel "github.com/harehare/textusm/pkg/domain/model/item"
	shareModel "github.com/harehare/textusm/pkg/domain/model/share"
	"github.com/harehare/textusm/pkg/domain/service"
	v "github.com/harehare/textusm/pkg/domain/values"
)

type Resolver struct {
	service *service.Service
	client  *firestore.Client
}

func New(service *service.Service, client *firestore.Client) *Resolver {
	r := Resolver{service: service, client: client}
	return &r
}

func (r *mutationResolver) Save(ctx context.Context, input InputItem, isPublic *bool) (*itemModel.Item, error) {
	if input.ID == nil {
		saveItem := itemModel.Item{
			ID:         "",
			Title:      input.Title,
			Text:       input.Text,
			Thumbnail:  input.Thumbnail,
			Diagram:    *input.Diagram,
			IsPublic:   input.IsPublic,
			IsBookmark: input.IsBookmark,
			Tags:       input.Tags,
			CreatedAt:  time.Now(),
			UpdatedAt:  time.Now(),
		}
		return r.service.SaveDiagram(ctx, &saveItem, *isPublic)
	}
	baseItem, err := r.service.FindDiagram(ctx, *input.ID, false)

	if err != nil {
		return nil, err
	}

	saveItem := itemModel.Item{
		ID:         baseItem.ID,
		Title:      input.Title,
		Text:       input.Text,
		Thumbnail:  input.Thumbnail,
		Diagram:    *input.Diagram,
		IsPublic:   input.IsPublic,
		IsBookmark: input.IsBookmark,
		Tags:       input.Tags,
		CreatedAt:  baseItem.CreatedAt,
		UpdatedAt:  time.Now(),
	}

	return r.service.SaveDiagram(ctx, &saveItem, *isPublic)
}

func (r *mutationResolver) Delete(ctx context.Context, itemID *v.ItemID, isPublic *bool) (*v.ItemID, error) {
	err := r.client.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
		ctx = values.WithTx(ctx, tx)
		return r.service.DeleteDiagram(ctx, *itemID, *isPublic)
	})

	if err != nil {
		return nil, err
	}

	return itemID, nil
}

func (r *mutationResolver) Bookmark(ctx context.Context, itemID *v.ItemID, isBookmark bool) (*itemModel.Item, error) {
	return r.service.Bookmark(ctx, *itemID, isBookmark)
}

func (r *queryResolver) Item(ctx context.Context, id *v.ItemID, isPublic *bool) (*itemModel.Item, error) {
	return r.service.FindDiagram(ctx, *id, *isPublic)
}

func (r *queryResolver) Items(ctx context.Context, offset *int, limit *int, isBookmark *bool, isPublic *bool) ([]*itemModel.Item, error) {
	return r.service.FindDiagrams(ctx, *offset, *limit, *isPublic)
}

func (r *queryResolver) ShareItem(ctx context.Context, token string, password *string) (*itemModel.Item, error) {
	var p string
	if password == nil {
		p = ""
	} else {
		p = *password
	}
	return r.service.FindShareItem(ctx, token, p)
}

func (r *queryResolver) ShareCondition(ctx context.Context, itemID *v.ItemID) (*shareModel.ShareCondition, error) {
	return r.service.FindShareCondition(ctx, *itemID)
}

func (r *mutationResolver) Share(ctx context.Context, input InputShareItem) (string, error) {
	var p string
	if input.Password == nil {
		p = ""
	} else {
		p = *input.Password
	}
	jwtToken, err := r.service.Share(ctx, *input.ItemID, *input.ExpSecond, p, input.AllowIPList, input.AllowEmailList)
	return *jwtToken, err
}

// Mutation returns MutationResolver implementation.
func (r *Resolver) Mutation() MutationResolver { return &mutationResolver{r} }

// Query returns QueryResolver implementation.
func (r *Resolver) Query() QueryResolver { return &queryResolver{r} }

type mutationResolver struct{ *Resolver }
type queryResolver struct{ *Resolver }
