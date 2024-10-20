package service

import (
	"context"

	"github.com/harehare/textusm/internal/context/values"
	"github.com/harehare/textusm/internal/db"
	settingsModel "github.com/harehare/textusm/internal/domain/model/settings"
	settingsRepo "github.com/harehare/textusm/internal/domain/repository/settings"
	v "github.com/harehare/textusm/internal/domain/values"
	"github.com/harehare/textusm/internal/github"
	"github.com/samber/mo"
)

type SettingsService struct {
	repo         settingsRepo.SettingsRepository
	transaction  db.Transaction
	clientID     github.ClientID
	clientSecret github.ClientSecret
}

func NewSettingsService(r settingsRepo.SettingsRepository, transaction db.Transaction, clientID github.ClientID, clientSecret github.ClientSecret) *SettingsService {
	return &SettingsService{
		repo:         r,
		transaction:  transaction,
		clientID:     clientID,
		clientSecret: clientSecret,
	}
}

func (s *SettingsService) Find(ctx context.Context, diagram v.Diagram) mo.Result[*settingsModel.Settings] {
	var settings settingsModel.Settings
	err := s.transaction.Do(ctx, func(ctx context.Context) error {
		if err := isAuthenticated(ctx); err != nil {
			return err
		}
		r := s.repo.Find(ctx, values.GetUID(ctx).OrEmpty(), diagram)

		if r.IsError() {
			return r.Error()
		}

		settings = *r.MustGet()
		return nil
	})

	if err != nil {
		return mo.Err[*settingsModel.Settings](err)
	}

	return mo.Ok(&settings)
}

func (s *SettingsService) Save(ctx context.Context, diagram v.Diagram, settings *settingsModel.Settings) mo.Result[*settingsModel.Settings] {
	var updatedSettings settingsModel.Settings
	err := s.transaction.Do(ctx, func(ctx context.Context) error {
		if err := isAuthenticated(ctx); err != nil {
			return err
		}

		r := s.repo.Save(ctx, values.GetUID(ctx).MustGet(), diagram, *settings)

		if r.IsError() {
			return r.Error()
		}
		updatedSettings = *r.MustGet()
		return nil
	})

	if err != nil {
		return mo.Err[*settingsModel.Settings](err)
	}

	return mo.Ok(&updatedSettings)
}
