package service

import (
	"context"

	"github.com/harehare/textusm/pkg/context/values"
	settingsModel "github.com/harehare/textusm/pkg/domain/model/settings"
	settingsRepo "github.com/harehare/textusm/pkg/domain/repository/settings"
	v "github.com/harehare/textusm/pkg/domain/values"
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

func (s *SettingsService) Find(ctx context.Context, diagram v.Diagram) (*settingsModel.Settings, error) {
	if err := isAuthenticated(ctx); err != nil {
		return nil, err
	}

	userID := values.GetUID(ctx)
	settings, err := s.repo.Find(ctx, *userID, diagram)

	if err != nil {
		return nil, err
	}

	return settings, nil
}

func (s *SettingsService) Save(ctx context.Context, diagram v.Diagram, settings *settingsModel.Settings) (*settingsModel.Settings, error) {
	if err := isAuthenticated(ctx); err != nil {
		return nil, err
	}

	userID := values.GetUID(ctx)
	return s.repo.Save(ctx, *userID, diagram, *settings)
}
