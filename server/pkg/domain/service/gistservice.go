package service

import (
	"context"

	itemModel "github.com/harehare/textusm/pkg/domain/model/item"
	itemRepo "github.com/harehare/textusm/pkg/domain/repository/item"
	v "github.com/harehare/textusm/pkg/domain/values"
)

type GistService struct {
	repo itemRepo.GistItemRepository
}

func NewGistService(r itemRepo.GistItemRepository) *GistService {
	return &GistService{
		repo: r,
	}
}

func (g *GistService) FindDiagrams(ctx context.Context, offset, limit int) ([]*itemModel.GistItem, error) {
	panic("not implemented")
}

func (g *GistService) FindDiagram(ctx context.Context, itemID v.GistID) (*itemModel.GistItem, error) {
	panic("not implemented")
}

func (g *GistService) SaveDiagram(ctx context.Context, item *itemModel.GistItem) (*itemModel.GistItem, error) {
	panic("not implemented")
}

func (g *GistService) DeleteDiagram(ctx context.Context, gistID v.GistID) error {
	panic("not implemented")
}
