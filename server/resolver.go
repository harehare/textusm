//go:generate go run github.com/99designs/gqlgen
package server

// THIS CODE IS A STARTING POINT ONLY. IT WILL NOT BE UPDATED WITH SCHEMA CHANGES.

import (
	"context"
	"time"

	"github.com/harehare/textusm/pkg/item"
)

type Resolver struct {
	service *item.Service
}

func (r *mutationResolver) Save(ctx context.Context, input item.InputItem) (*item.Item, error) {

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
		return r.service.SaveDiagram(ctx, &saveItem)
	}
	baseItem, err := r.service.FindDiagram(ctx, *input.ID)

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

	return r.service.SaveDiagram(ctx, &saveItem)
}

func (r *mutationResolver) Delete(ctx context.Context, itemID string) (*item.Item, error) {
	diagramItem, err := r.service.FindDiagram(ctx, itemID)

	if err != nil {
		return nil, err
	}

	err = r.service.DeleteDiagram(ctx, itemID)

	if err != nil {
		return nil, err
	}

	return diagramItem, nil
}

func (r *mutationResolver) Bookmark(ctx context.Context, itemID string, isBookmark bool) (*item.Item, error) {
	diagramItem, err := r.service.FindDiagram(ctx, itemID)

	if err != nil {
		return nil, err
	}
	diagramItem.IsBookmark = isBookmark
	return r.service.SaveDiagram(ctx, diagramItem)
}

func (r *queryResolver) Item(ctx context.Context, id string) (*item.Item, error) {
	return r.service.FindDiagram(ctx, id)
}

func (r *queryResolver) Items(ctx context.Context, offset *int, limit *int, isBookmark *bool, isPublic *bool) ([]*item.Item, error) {
	return r.service.FindDiagrams(ctx, *offset, *limit, *isPublic)
}

// Mutation returns MutationResolver implementation.
func (r *Resolver) Mutation() MutationResolver { return &mutationResolver{r} }

// Query returns QueryResolver implementation.
func (r *Resolver) Query() QueryResolver { return &queryResolver{r} }

type mutationResolver struct{ *Resolver }
type queryResolver struct{ *Resolver }
