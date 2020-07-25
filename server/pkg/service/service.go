package service

import (
	"context"
	"log"
	"os"
	"strconv"

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
	log.Println("Find diagrams offset = " + strconv.Itoa(offset) + ", limit = " + strconv.Itoa(limit))
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
	log.Println("Find diagram id = " + itemID)
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
	log.Println("Save diagram id = " + item.ID)
	userID := ctx.Value(middleware.UIDKey).(string)
	currentText := item.Text
	text, err := Encrypt(encryptKey, item.Text)

	if err != nil {
		return nil, err
	}

	item.Text = text
	item.IsPublic = isPublic

	if isPublic {
		isOwner, err := s.isPublicDiagramOwner(ctx, item.ID, userID)

		if !isOwner {
			return nil, e.NoAuthorizationError(err)
		}
		_, err = s.repo.Save(ctx, userID, item, true)

		if err != nil {
			return nil, err
		}

		log.Println("Save public diagram id = " + item.ID)
	} else {
		_, err := s.repo.FindByID(ctx, userID, item.ID, true)

		if err == nil || e.GetCode(err) != e.NotFound {
			err := s.repo.Delete(ctx, userID, item.ID, true)

			if err != nil {
				return nil, err
			}
			log.Println("Delete public diagram id = " + item.ID)
		}
	}

	resultItem, err := s.repo.Save(ctx, userID, item, false)
	item.Text = currentText
	resultItem.IsPublic = isPublic

	return resultItem, err
}

func (s *Service) DeleteDiagram(ctx context.Context, itemID string, isPublic bool) error {
	log.Println("Delete diagram id = " + itemID)
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
		log.Println("Delete public diagram id = " + itemID)
	}

	return s.repo.Delete(ctx, userID, itemID, false)
}

func (s *Service) isPublicDiagramOwner(ctx context.Context, itemID, ownerUserID string) (bool, error) {

	if itemID == "" {
		return true, nil
	}

	_, err := s.repo.FindByID(ctx, ownerUserID, itemID, false)
	isOwner := err == nil

	if e.GetCode(err) == e.NotFound {
		return isOwner, nil
	}

	return isOwner, err
}
