package service

import (
	"context"

	"github.com/harehare/textusm/internal/context/values"
	"github.com/harehare/textusm/internal/db"
	"github.com/harehare/textusm/internal/domain/model/item/gistitem"
	itemRepo "github.com/harehare/textusm/internal/domain/repository/item"
	"github.com/harehare/textusm/internal/github"
	"github.com/samber/mo"
)

type GistService struct {
	repo         itemRepo.GistItemRepository
	transaction  db.Transaction
	clientID     github.ClientID
	clientSecret github.ClientSecret
}

func NewGistService(r itemRepo.GistItemRepository, transaction db.Transaction, clientID github.ClientID, clientSecret github.ClientSecret) *GistService {
	return &GistService{
		repo:         r,
		transaction:  transaction,
		clientID:     clientID,
		clientSecret: clientSecret,
	}
}

func (g *GistService) Find(ctx context.Context, offset, limit int) mo.Result[[]*gistitem.GistItem] {
	var items []*gistitem.GistItem
	err := g.transaction.Do(ctx, func(ctx context.Context) error {
		if err := isAuthenticated(ctx); err != nil {
			return err
		}

		userID := values.GetUID(ctx)
		r := g.repo.Find(ctx, userID.OrEmpty(), offset, limit)

		if r.IsError() {
			return r.Error()
		}

		items = r.MustGet()
		return nil
	})

	if err != nil {
		return mo.Err[[]*gistitem.GistItem](err)
	}

	return mo.Ok(items)
}

func (g *GistService) FindByID(ctx context.Context, gistID string) mo.Result[*gistitem.GistItem] {
	var item *gistitem.GistItem
	err := g.transaction.Do(ctx, func(ctx context.Context) error {
		if err := isAuthenticated(ctx); err != nil {
			return err
		}

		userID := values.GetUID(ctx)
		r := g.repo.FindByID(ctx, userID.OrEmpty(), gistID)

		if r.IsError() {
			return r.Error()
		}

		item = r.MustGet()
		return nil
	})

	if err != nil {
		return mo.Err[*gistitem.GistItem](err)
	}

	return mo.Ok(item)
}

func (g *GistService) Save(ctx context.Context, gist *gistitem.GistItem) mo.Result[*gistitem.GistItem] {
	var item *gistitem.GistItem
	err := g.transaction.Do(ctx, func(ctx context.Context) error {
		if err := isAuthenticated(ctx); err != nil {
			return err
		}

		r := g.repo.Save(ctx, values.GetUID(ctx).OrEmpty(), gist)

		if r.IsError() {
			return r.Error()
		}
		item = r.MustGet()
		return nil
	})

	if err != nil {
		return mo.Err[*gistitem.GistItem](err)
	}

	return mo.Ok(item)
}

func (g *GistService) Delete(ctx context.Context, gistID string) mo.Result[bool] {
	err := g.transaction.Do(ctx, func(ctx context.Context) error {
		if err := isAuthenticated(ctx); err != nil {
			return err
		}

		return g.repo.Delete(ctx, values.GetUID(ctx).OrEmpty(), gistID).Error()
	})

	if err != nil {
		return mo.Err[bool](err)
	}

	return mo.Ok(true)
}
