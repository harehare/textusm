package service

import (
	"context"

	"github.com/harehare/textusm/pkg/context/values"
	"github.com/harehare/textusm/pkg/domain/model/item/gistitem"
	itemRepo "github.com/harehare/textusm/pkg/domain/repository/item"
)

type GistService struct {
	repo         itemRepo.GistItemRepository
	clientID     string
	clientSecret string
}

func NewGistService(r itemRepo.GistItemRepository, clientID, clientSecret string) *GistService {
	return &GistService{
		repo:         r,
		clientID:     clientID,
		clientSecret: clientSecret,
	}
}

func (g *GistService) Find(ctx context.Context, offset, limit int) ([]*gistitem.GistItem, error) {
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

func (g *GistService) FindByID(ctx context.Context, gistID string) (*gistitem.GistItem, error) {
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

func (g *GistService) Save(ctx context.Context, gist *gistitem.GistItem) (*gistitem.GistItem, error) {
	if err := isAuthenticated(ctx); err != nil {
		return nil, err
	}

	userID := values.GetUID(ctx)
	return g.repo.Save(ctx, *userID, gist)
}

func (g *GistService) Delete(ctx context.Context, gistID string) error {
	if err := isAuthenticated(ctx); err != nil {
		return err
	}

	userID := values.GetUID(ctx)
	return g.repo.Delete(ctx, *userID, gistID)
}

func (g *GistService) RevokeToken(ctx context.Context, accessToken string) error {
	if err := isAuthenticated(ctx); err != nil {
		return err
	}

	return g.repo.RevokeToken(ctx, g.clientID, g.clientSecret, accessToken)
}
