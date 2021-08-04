package graphql

import (
	"context"
	"time"

	"cloud.google.com/go/firestore"
	"github.com/harehare/textusm/pkg/context/values"
	itemModel "github.com/harehare/textusm/pkg/domain/model/item"
	v "github.com/harehare/textusm/pkg/domain/values"
)

func (r *Resolver) Mutation() MutationResolver { return &mutationResolver{r} }

type mutationResolver struct{ *Resolver }

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
			CreatedAt:  time.Now(),
			UpdatedAt:  time.Now(),
		}
		return r.service.Save(ctx, &saveItem, *isPublic)
	}
	baseItem, err := r.service.FindByID(ctx, *input.ID, false)

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
		CreatedAt:  baseItem.CreatedAt,
		UpdatedAt:  time.Now(),
	}

	return r.service.Save(ctx, &saveItem, *isPublic)
}

func (r *mutationResolver) Delete(ctx context.Context, itemID *v.ItemID, isPublic *bool) (*v.ItemID, error) {
	err := r.client.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
		ctx = values.WithTx(ctx, tx)
		return r.service.Delete(ctx, *itemID, *isPublic)
	})

	if err != nil {
		return nil, err
	}

	return itemID, nil
}

func (r *mutationResolver) Bookmark(ctx context.Context, itemID *v.ItemID, isBookmark bool) (*itemModel.Item, error) {
	return r.service.Bookmark(ctx, *itemID, isBookmark)
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

func (r *mutationResolver) SaveGist(ctx context.Context, input InputGistItem) (*itemModel.GistItem, error) {
	gist := itemModel.GistItem{
		ID:         *input.ID,
		Title:      input.Title,
		Thumbnail:  input.Thumbnail,
		Diagram:    *input.Diagram,
		IsBookmark: input.IsBookmark,
		CreatedAt:  time.Now(),
		UpdatedAt:  time.Now(),
	}
	return r.gistService.Save(ctx, &gist)
}

func (r *mutationResolver) DeleteGist(ctx context.Context, gistID *v.GistID) (*v.GistID, error) {
	err := r.gistService.Delete(ctx, *gistID)
	return gistID, err
}
