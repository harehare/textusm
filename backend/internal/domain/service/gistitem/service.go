package gistitem

import (
	"context"

	"github.com/harehare/textusm/internal/context/values"
	"github.com/harehare/textusm/internal/db"
	"github.com/harehare/textusm/internal/domain/model/gistitem"
	itemRepo "github.com/harehare/textusm/internal/domain/repository/gistitem"
	"github.com/harehare/textusm/internal/domain/service/user"
	"github.com/harehare/textusm/internal/github"
	"github.com/samber/mo"
)

type Service struct {
	repo         itemRepo.GistItemRepository
	transaction  db.Transaction
	clientID     github.ClientID
	clientSecret github.ClientSecret
}

func NewService(r itemRepo.GistItemRepository, transaction db.Transaction, clientID github.ClientID, clientSecret github.ClientSecret) *Service {
	return &Service{
		repo:         r,
		transaction:  transaction,
		clientID:     clientID,
		clientSecret: clientSecret,
	}
}

func (s *Service) Find(ctx context.Context, offset, limit int) mo.Result[[]*gistitem.GistItem] {
	var items []*gistitem.GistItem
	err := s.transaction.Do(ctx, func(ctx context.Context) error {
		if err := user.IsAuthenticated(ctx); err != nil {
			return err
		}

		userID := values.GetUID(ctx)
		r := s.repo.Find(ctx, userID.OrEmpty(), offset, limit)

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

func (s *Service) FindByID(ctx context.Context, gistID string) mo.Result[*gistitem.GistItem] {
	var item *gistitem.GistItem
	err := s.transaction.Do(ctx, func(ctx context.Context) error {
		if err := user.IsAuthenticated(ctx); err != nil {
			return err
		}

		userID := values.GetUID(ctx)
		r := s.repo.FindByID(ctx, userID.OrEmpty(), gistID)

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

func (s *Service) Save(ctx context.Context, gist *gistitem.GistItem) mo.Result[*gistitem.GistItem] {
	var item *gistitem.GistItem
	err := s.transaction.Do(ctx, func(ctx context.Context) error {
		if err := user.IsAuthenticated(ctx); err != nil {
			return err
		}

		r := s.repo.Save(ctx, values.GetUID(ctx).OrEmpty(), gist)

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

func (s *Service) Delete(ctx context.Context, gistID string) mo.Result[bool] {
	err := s.transaction.Do(ctx, func(ctx context.Context) error {
		if err := user.IsAuthenticated(ctx); err != nil {
			return err
		}

		return s.repo.Delete(ctx, values.GetUID(ctx).OrEmpty(), gistID).Error()
	})

	if err != nil {
		return mo.Err[bool](err)
	}

	return mo.Ok(true)
}
