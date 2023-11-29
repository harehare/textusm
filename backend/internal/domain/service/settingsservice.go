package service

import (
	"context"

	"github.com/harehare/textusm/internal/context/values"
	settingsModel "github.com/harehare/textusm/internal/domain/model/settings"
	settingsRepo "github.com/harehare/textusm/internal/domain/repository/settings"
	v "github.com/harehare/textusm/internal/domain/values"
	"github.com/samber/mo"
)

type SettingsService struct {
	repo         settingsRepo.SettingsRepository
	clientID     string
	clientSecret string
}

func NewSettingsService(r settingsRepo.SettingsRepository, clientID, clientSecret string) *SettingsService {
	return &SettingsService{
		repo:         r,
		clientID:     clientID,
		clientSecret: clientSecret,
	}
}

func (s *SettingsService) Find(ctx context.Context, diagram v.Diagram) mo.Result[*settingsModel.Settings] {
	if err := isAuthenticated(ctx); err != nil {
		return mo.Err[*settingsModel.Settings](err)
	}

	return s.repo.Find(ctx, values.GetUID(ctx).OrEmpty(), diagram)
}

func (s *SettingsService) Save(ctx context.Context, diagram v.Diagram, settings *settingsModel.Settings) mo.Result[*settingsModel.Settings] {
	if err := isAuthenticated(ctx); err != nil {
		return mo.Err[*settingsModel.Settings](err)
	}

	return s.repo.Save(ctx, values.GetUID(ctx).OrEmpty(), diagram, *settings)
}

func (s *SettingsService) FindFontList(ctx context.Context, lang string) mo.Result[[]string] {
	return s.repo.FindFontList(ctx, lang)
}
