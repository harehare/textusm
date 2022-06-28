package service

import (
	"context"

	"github.com/harehare/textusm/pkg/context/values"
	"github.com/harehare/textusm/pkg/domain/model/item/gistitem"
	itemRepo "github.com/harehare/textusm/pkg/domain/repository/item"
	"github.com/samber/mo"
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

func (g *GistService) Find(ctx context.Context, offset, limit int) mo.Result[[]*gistitem.GistItem] {
	if err := isAuthenticated(ctx); err != nil {
		return mo.Err[[]*gistitem.GistItem](err)
	}

	userID := values.GetUID(ctx)
	return g.repo.Find(ctx, userID.OrEmpty(), offset, limit)
}

func (g *GistService) FindByID(ctx context.Context, gistID string) mo.Result[*gistitem.GistItem] {
	if err := isAuthenticated(ctx); err != nil {
		return mo.Err[*gistitem.GistItem](err)
	}

	userID := values.GetUID(ctx)
	return g.repo.FindByID(ctx, userID.OrEmpty(), gistID)
}

func (g *GistService) Save(ctx context.Context, gist *gistitem.GistItem) mo.Result[*gistitem.GistItem] {
	if err := isAuthenticated(ctx); err != nil {
		return mo.Err[*gistitem.GistItem](err)
	}

	return g.repo.Save(ctx, values.GetUID(ctx).OrEmpty(), gist)
}

func (g *GistService) Delete(ctx context.Context, gistID string) error {
	if err := isAuthenticated(ctx); err != nil {
		return err
	}

	return g.repo.Delete(ctx, values.GetUID(ctx).OrEmpty(), gistID)
}

func (g *GistService) RevokeToken(ctx context.Context, accessToken string) error {
	if err := isAuthenticated(ctx); err != nil {
		return err
	}

	return g.repo.RevokeToken(ctx, g.clientID, g.clientSecret, accessToken)
}
