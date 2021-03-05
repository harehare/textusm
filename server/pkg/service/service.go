package service

import (
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"errors"
	"os"

	e "github.com/harehare/textusm/pkg/error"
	"github.com/harehare/textusm/pkg/item"
	"github.com/harehare/textusm/pkg/repository"
	"github.com/harehare/textusm/pkg/values"
	"github.com/rs/zerolog/log"
)

var encryptKey = []byte(os.Getenv("ENCRYPT_KEY"))
var shareEncryptKey = []byte(os.Getenv("SHARE_ENCRYPT_KEY"))

type Service struct {
	repo      repository.ItemRepository
	shareRepo repository.ShareRepository
}

func NewService(r repository.ItemRepository, s repository.ShareRepository) *Service {
	return &Service{
		repo:      r,
		shareRepo: s,
	}
}

func (s *Service) FindDiagrams(ctx context.Context, offset, limit int, isPublic bool) ([]*item.Item, error) {
	requestID := values.GetRequestID(ctx)
	log.Info().Str("request_id", requestID).Int("offset", offset).Int("limit", limit).Msg("Start find diagrams")
	userID := values.GetUID(ctx)
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
	requestID := values.GetRequestID(ctx)
	log.Info().Str("request_id", requestID).Str("item_id", itemID).Msg("Start Find diagram")
	userID := values.GetUID(ctx)
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
	requestID := values.GetRequestID(ctx)
	log.Info().Str("request_id", requestID).Str("item_id", item.ID).Msg("Save diagram")
	userID := values.GetUID(ctx)
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

	return resultItem, err
}

func (s *Service) DeleteDiagram(ctx context.Context, itemID string, isPublic bool) error {
	requestID := values.GetRequestID(ctx)
	log.Info().Str("request_id", requestID).Str("item_id", itemID).Msg("Start delete diagram")
	userID := values.GetUID(ctx)

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

func (s *Service) Bookmark(ctx context.Context, itemID string, isBookmark bool) (*item.Item, error) {
	requestID := values.GetRequestID(ctx)
	log.Info().Str("request_id", requestID).Str("item_id", itemID).Msg("Start bookmark")
	diagramItem, err := s.FindDiagram(ctx, itemID, false)

	if err != nil {
		return nil, err
	}
	diagramItem.IsBookmark = isBookmark
	return s.SaveDiagram(ctx, diagramItem, false)
}

func (s *Service) FindShareItem(ctx context.Context, hashKey string) (*item.Item, error) {
	requestID := values.GetRequestID(ctx)
	log.Info().Str("request_id", requestID).Str("hash_key", hashKey).Msg("Start share diagram")
	userID := values.GetUID(ctx)

	if userID == "" {
		return nil, e.NoAuthorizationError(errors.New("Not Authorization"))
	}

	item, err := s.shareRepo.FindByID(ctx, hashKey)

	if err != nil {
		return nil, err
	}

	return item, nil
}

func (s *Service) Share(ctx context.Context, itemID string) (*string, error) {
	requestID := values.GetRequestID(ctx)
	log.Info().Str("request_id", requestID).Str("item_id", itemID).Msg("Start share diagram")
	userID := values.GetUID(ctx)

	if userID == "" {
		return nil, e.NoAuthorizationError(errors.New("Not Authorization"))
	}

	hash := sha256.Sum256([]byte(itemID))
	mac := hmac.New(sha256.New, hash[:])
	_, err := mac.Write([]byte(shareEncryptKey))

	if err != nil {
		return nil, err
	}

	item, err := s.repo.FindByID(ctx, userID, itemID, false)

	if err != nil {
		return nil, err
	}

	hashKey := string(mac.Sum(nil))

	if err := s.shareRepo.Save(ctx, hashKey, item); err != nil {
		return nil, err
	}

	return &hashKey, nil
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
