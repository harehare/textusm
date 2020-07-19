package service

import (
	"context"
	"os"

	"github.com/harehare/textusm/api/middleware"
	e "github.com/harehare/textusm/pkg/error"
	"github.com/harehare/textusm/pkg/item"
	"github.com/harehare/textusm/pkg/repository"
)

var encryptKey = []byte(os.Getenv("ENCRYPT_KEY"))

type Service struct {
	repo repository.Repository
}

func NewService(r repository.Repository) *Service {
	return &Service{
		repo: r,
	}
}

func (s *Service) FindDiagrams(ctx context.Context, offset, limit int, isPublic bool) ([]*item.Item, error) {
	userID := ctx.Value(middleware.UIDKey).(string)
	items, err := s.repo.Find(ctx, userID, offset, limit, isPublic)

	if err != nil {
		return nil, err
	}

	resultItems := make([]*item.Item, len(items))

	for i, item := range items {
		if item.Text != "" {
			text, err := Decrypt(encryptKey, item.Text)
			if err != nil {
				return nil, err
			}
			item.Text = text
		}

		resultItems[i] = item
	}

	return resultItems, nil
}

func (s *Service) FindDiagram(ctx context.Context, itemID string, isPublic bool) (*item.Item, error) {
	userID := ctx.Value(middleware.UIDKey).(string)
	item, err := s.repo.FindByID(ctx, userID, itemID, isPublic)

	if err != nil {
		return nil, err
	}

	text, err := Decrypt(encryptKey, item.Text)

	if err != nil {
		return nil, err
	}

	item.Text = text
	return item, nil
}

func (s *Service) SaveDiagram(ctx context.Context, item *item.Item, isPublic bool) (*item.Item, error) {
	userID := ctx.Value(middleware.UIDKey).(string)

	if isPublic {
		isOwner, err := s.isPublicDiagramOwner(ctx, item.ID, userID)

		if !isOwner {
			return nil, e.NoAuthorizationError(err)
		}
	}

	currentText := item.Text
	text, err := Encrypt(encryptKey, item.Text)

	if err != nil {
		return nil, err
	}

	item.Text = text

	if isPublic {
		_, err = s.repo.Save(ctx, userID, item, true)

		if err != nil {
			return nil, err
		}
	}

	resultItem, err := s.repo.Save(ctx, userID, item, false)
	item.Text = currentText

	return resultItem, err
}

func (s *Service) DeleteDiagram(ctx context.Context, itemID string, isPublic bool) error {
	userID := ctx.Value(middleware.UIDKey).(string)

	if isPublic {
		isOwner, err := s.isPublicDiagramOwner(ctx, itemID, userID)

		if !isOwner {
			return e.NoAuthorizationError(err)
		}
	}

	if isPublic {
		err := s.repo.Delete(ctx, userID, itemID, true)

		if err != nil {
			return err
		}
	}

	return s.repo.Delete(ctx, userID, itemID, false)
}

func (s *Service) isPublicDiagramOwner(ctx context.Context, itemID, ownerUserID string) (bool, error) {
	_, err := s.repo.FindByID(ctx, ownerUserID, itemID, false)
	isOwner := err == nil

	if e.GetCode(err) == e.NotFound {
		return isOwner, nil
	}

	return isOwner, err
}
