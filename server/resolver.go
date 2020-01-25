//go:generate go run github.com/99designs/gqlgen
package server

import (
	"context"
	"time"

	"github.com/harehare/textusm/pkg/item"
)

type Resolver struct {
	service *item.Service
}

func (r *Resolver) Mutation() MutationResolver {
	return &mutationResolver{r}
}
func (r *Resolver) Query() QueryResolver {
	return &queryResolver{r}
}

type mutationResolver struct{ *Resolver }

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

type queryResolver struct{ *Resolver }

func (r *queryResolver) Item(ctx context.Context, id string) (*item.Item, error) {
	return r.service.FindDiagram(ctx, id)
}
func (r *queryResolver) Items(ctx context.Context, first *int, offset *int, isBookmark *bool, isPublic *bool) ([]*item.Item, error) {
	return r.service.FindDiagrams(ctx, *first, *offset, *isBookmark, *isPublic)
}
