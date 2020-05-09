package item

import (
	"context"
	"os"

	"github.com/harehare/textusm/api/middleware"
)

var encryptKey = []byte(os.Getenv("ENCRYPT_KEY"))

type Service struct {
	repo Repository
}

func NewService(r Repository) *Service {
	return &Service{
		repo: r,
	}
}

func (s *Service) FindDiagrams(ctx context.Context, offset, limit int, isPublic bool) ([]*Item, error) {
	userID := ctx.Value(middleware.UIDKey).(string)
	items, err := s.repo.Find(ctx, userID, offset, limit, isPublic)

	if err != nil {
		return nil, err
	}

	resultItems := make([]*Item, len(items))

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

func (s *Service) FindDiagram(ctx context.Context, itemID string) (*Item, error) {
	userID := ctx.Value(middleware.UIDKey).(string)
	item, err := s.repo.FindByID(ctx, userID, itemID)

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

func (s *Service) SaveDiagram(ctx context.Context, item *Item) (*Item, error) {
	userID := ctx.Value(middleware.UIDKey).(string)
	currentText := item.Text
	text, err := Encrypt(encryptKey, item.Text)

	if err != nil {
		return nil, err
	}

	item.Text = text
	resultItem, err := s.repo.Save(ctx, userID, item)
	item.Text = currentText

	return resultItem, err
}

func (s *Service) DeleteDiagram(ctx context.Context, itemID string) error {
	userID := ctx.Value(middleware.UIDKey).(string)
	return s.repo.Delete(ctx, userID, itemID)
}
