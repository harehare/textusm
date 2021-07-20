package server

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
	panic("not implemented")
}

func (r *mutationResolver) DeleteGist(ctx context.Context, itemID *v.GistID) (*v.GistID, error) {
	panic("not implemented")
}
