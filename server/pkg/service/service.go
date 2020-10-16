package service

import (
	"context"
	"os"

	"github.com/harehare/textusm/api/middleware"
	e "github.com/harehare/textusm/pkg/error"
	"github.com/harehare/textusm/pkg/item"
	"github.com/harehare/textusm/pkg/repository"
	"github.com/rs/zerolog/log"
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
	requestID := ctx.Value(middleware.RequestIDKey).(string)
	log.Info().Str("request_id", requestID).Int("offset", offset).Int("limit", limit).Msg("Start find diagrams")
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

	log.Info().Str("request_id", requestID).Msg("End find diagrams")
	return resultItems, nil
}

func (s *Service) FindDiagram(ctx context.Context, itemID string, isPublic bool) (*item.Item, error) {
	requestID := ctx.Value(middleware.RequestIDKey).(string)
	log.Info().Str("request_id", requestID).Str("item_id", itemID).Msg("Start Find diagram")
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
	log.Info().Str("request_id", requestID).Msg("End Find diagram")
	return item, nil
}

func (s *Service) SaveDiagram(ctx context.Context, item *item.Item, isPublic bool) (*item.Item, error) {
	requestID := ctx.Value(middleware.RequestIDKey).(string)
	log.Info().Str("request_id", requestID).Str("item_id", item.ID).Msg("Save diagram")
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

		log.Info().Str("request_id", requestID).Str("item_id", item.ID).Msg("Save public diagram")
	} else if item.ID != "" {
		_, err := s.repo.FindByID(ctx, userID, item.ID, true)

		if err == nil || e.GetCode(err) != e.NotFound {
			err := s.repo.Delete(ctx, userID, item.ID, true)

			if err != nil {
				return nil, err
			}
			log.Info().Str("request_id", requestID).Str("item_id", item.ID).Msg("Delete public diagram")
		}
	}

	resultItem, err := s.repo.Save(ctx, userID, item, false)
	item.Text = currentText
	resultItem.IsPublic = isPublic

	log.Info().Str("request_id", requestID).Msg("End save diagram")
	return resultItem, err
}

func (s *Service) DeleteDiagram(ctx context.Context, itemID string, isPublic bool) error {
	requestID := ctx.Value(middleware.RequestIDKey).(string)
	log.Info().Str("request_id", requestID).Str("item_id", itemID).Msg("Start delete diagram")
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
		log.Info().Str("request_id", requestID).Str("item_id", itemID).Msg("Delete public diagram")
	}

	log.Info().Str("request_id", requestID).Msg("End delete public diagram")
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
