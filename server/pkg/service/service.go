package service

import (
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"os"

	e "github.com/harehare/textusm/pkg/error"
	"github.com/harehare/textusm/pkg/item"
	"github.com/harehare/textusm/pkg/repository"
	"github.com/harehare/textusm/pkg/values"
)

var (
	encryptKey      = []byte(os.Getenv("ENCRYPT_KEY"))
	shareEncryptKey = []byte(os.Getenv("SHARE_ENCRYPT_KEY"))
)

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

func isAuthenticated(ctx context.Context) error {
	userID := values.GetUID(ctx)

	if userID == "" {
		return e.NoAuthorizationError(errors.New("Not Authorization"))
	}

	return nil
}

func (s *Service) FindDiagrams(ctx context.Context, offset, limit int, isPublic bool) ([]*item.Item, error) {
	if err := isAuthenticated(ctx); err != nil {
		return nil, err
	}

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
				return nil, e.DecryptionFailedError(err)
			}
			item.Text = text
		}

		resultItems[i] = item
	}

	return resultItems, nil
}

func (s *Service) FindDiagram(ctx context.Context, itemID string, isPublic bool) (*item.Item, error) {
	if err := isAuthenticated(ctx); err != nil {
		return nil, err
	}

	userID := values.GetUID(ctx)
	item, err := s.repo.FindByID(ctx, userID, itemID, isPublic)

	if err != nil {
		return nil, err
	}

	text, err := Decrypt(encryptKey, item.Text)

	if err != nil {
		return nil, e.DecryptionFailedError(err)
	}

	item.Text = text
	return item, nil
}

func (s *Service) SaveDiagram(ctx context.Context, item *item.Item, isPublic bool) (*item.Item, error) {
	if err := isAuthenticated(ctx); err != nil {
		return nil, err
	}

	userID := values.GetUID(ctx)
	currentText := item.Text
	text, err := Encrypt(encryptKey, item.Text)

	if err != nil {
		return nil, e.EncryptionFailedError(err)
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

	} else if item.ID != "" {
		_, err := s.repo.FindByID(ctx, userID, item.ID, true)

		if err == nil || e.GetCode(err) != e.NotFound {
			err := s.repo.Delete(ctx, userID, item.ID, true)

			if err != nil {
				return nil, err
			}
		}
	}

	resultItem, err := s.repo.Save(ctx, userID, item, false)
	item.Text = currentText
	resultItem.IsPublic = isPublic

	return resultItem, err
}

func (s *Service) DeleteDiagram(ctx context.Context, itemID string, isPublic bool) error {
	if err := isAuthenticated(ctx); err != nil {
		return err
	}

	userID := values.GetUID(ctx)
	shareID, err := itemIDToShareID(itemID)

	if err != nil {
		return err
	}

	if isPublic {
		isOwner, err := s.isPublicDiagramOwner(ctx, itemID, userID)

		if !isOwner {
			return e.NoAuthorizationError(err)
		}
	}

	if isPublic {
		if err := s.repo.Delete(ctx, userID, itemID, true); err != nil {
			return err
		}
	}

	if err := s.shareRepo.Delete(ctx, *shareID); err != nil {
		return err
	}

	return s.repo.Delete(ctx, userID, itemID, false)
}

func (s *Service) Bookmark(ctx context.Context, itemID string, isBookmark bool) (*item.Item, error) {
	if err := isAuthenticated(ctx); err != nil {
		return nil, err
	}

	diagramItem, err := s.FindDiagram(ctx, itemID, false)

	if err != nil {
		return nil, err
	}
	diagramItem.IsBookmark = isBookmark
	return s.SaveDiagram(ctx, diagramItem, false)
}

func (s *Service) FindShareItem(ctx context.Context, hashKey string) (*item.Item, error) {
	item, err := s.shareRepo.FindByID(ctx, hashKey)

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

func (s *Service) Share(ctx context.Context, itemID string) (*string, error) {
	userID := values.GetUID(ctx)

	if userID == "" {
		return nil, e.NoAuthorizationError(errors.New("Not Authorization"))
	}

	item, err := s.repo.FindByID(ctx, userID, itemID, false)

	if err != nil {
		return nil, err
	}

	shareID, err := itemIDToShareID(item.ID)

	if err != nil {
		return nil, err
	}

	if err := s.shareRepo.Save(ctx, *shareID, item); err != nil {
		return nil, err
	}

	return shareID, nil
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

func itemIDToShareID(itemID string) (*string, error) {
	mac := hmac.New(sha256.New, shareEncryptKey)
	_, err := mac.Write([]byte(itemID))

	if err != nil {
		return nil, err
	}

	hashKey := hex.EncodeToString(mac.Sum(nil))
	return &hashKey, nil
}
