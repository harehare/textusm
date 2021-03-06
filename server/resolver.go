//go:generate go run github.com/99designs/gqlgen
package server

// THIS CODE IS A STARTING POINT ONLY. IT WILL NOT BE UPDATED WITH SCHEMA CHANGES.

import (
	"context"
	"time"

	"github.com/harehare/textusm/pkg/item"
	"github.com/harehare/textusm/pkg/service"
)

type Resolver struct {
	service *service.Service
}

func (r *mutationResolver) Save(ctx context.Context, input item.InputItem, isPublic *bool) (*item.Item, error) {
	if input.ID == nil {
		saveItem := item.Item{
			ID:         "",
			Title:      input.Title,
			Text:       input.Text,
			Thumbnail:  input.Thumbnail,
			Diagram:    input.Diagram,
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

	saveItem := item.Item{
		ID:         baseItem.ID,
		Title:      input.Title,
		Text:       input.Text,
		Thumbnail:  input.Thumbnail,
		Diagram:    input.Diagram,
		IsPublic:   input.IsPublic,
		IsBookmark: input.IsBookmark,
		Tags:       input.Tags,
		CreatedAt:  baseItem.CreatedAt,
		UpdatedAt:  time.Now(),
	}

	return r.service.SaveDiagram(ctx, &saveItem, *isPublic)
}

func (r *mutationResolver) Delete(ctx context.Context, itemID string, isPublic *bool) (*item.Item, error) {
	diagramItem, err := r.service.FindDiagram(ctx, itemID, *isPublic)

	if err != nil {
		return nil, err
	}

	err = r.service.DeleteDiagram(ctx, itemID, *isPublic)

	if err != nil {
		return nil, err
	}

	return diagramItem, nil
}

func (r *mutationResolver) Bookmark(ctx context.Context, itemID string, isBookmark bool) (*item.Item, error) {
	return r.service.Bookmark(ctx, itemID, isBookmark)
}

func (r *queryResolver) Item(ctx context.Context, id string, isPublic *bool) (*item.Item, error) {
	return r.service.FindDiagram(ctx, id, *isPublic)
}

func (r *queryResolver) Items(ctx context.Context, offset *int, limit *int, isBookmark *bool, isPublic *bool) ([]*item.Item, error) {
	return r.service.FindDiagrams(ctx, *offset, *limit, *isPublic)
}

func (r *queryResolver) Share(ctx context.Context, id string) (string, error) {
	hashKey, err := r.service.Share(ctx, id)
	return *hashKey, err
}

// Mutation returns MutationResolver implementation.
func (r *Resolver) Mutation() MutationResolver { return &mutationResolver{r} }

// Query returns QueryResolver implementation.
func (r *Resolver) Query() QueryResolver { return &queryResolver{r} }

type mutationResolver struct{ *Resolver }
type queryResolver struct{ *Resolver }
