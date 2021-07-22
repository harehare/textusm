package service

import (
	"context"

	"github.com/harehare/textusm/pkg/context/values"
	itemModel "github.com/harehare/textusm/pkg/domain/model/item"
	itemRepo "github.com/harehare/textusm/pkg/domain/repository/item"
	v "github.com/harehare/textusm/pkg/domain/values"
)

type GistService struct {
	repo itemRepo.GistItemRepository
}

func NewGistService(r itemRepo.GistItemRepository) *GistService {
	return &GistService{
		repo: r,
	}
}

func (g *GistService) Find(ctx context.Context, offset, limit int) ([]*itemModel.GistItem, error) {
	if err := isAuthenticated(ctx); err != nil {
		return nil, err
	}

	userID := values.GetUID(ctx)
	items, err := g.repo.Find(ctx, *userID, offset, limit)

	if err != nil {
		return nil, err
	}

	return items, nil
}

func (g *GistService) FindByID(ctx context.Context, gistID v.GistID) (*itemModel.GistItem, error) {
	if err := isAuthenticated(ctx); err != nil {
		return nil, err
	}

	userID := values.GetUID(ctx)
	item, err := g.repo.FindByID(ctx, *userID, gistID)

	if err != nil {
		return nil, err
	}

	return item, nil
}

func (g *GistService) Save(ctx context.Context, gist *itemModel.GistItem) (*itemModel.GistItem, error) {
	if err := isAuthenticated(ctx); err != nil {
		return nil, err
	}

	userID := values.GetUID(ctx)
	return g.repo.Save(ctx, *userID, gist)
}

func (g *GistService) Delete(ctx context.Context, gistID v.GistID) error {
	if err := isAuthenticated(ctx); err != nil {
		return err
	}

	userID := values.GetUID(ctx)
	return g.repo.Delete(ctx, *userID, gistID)
}
