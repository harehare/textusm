//go:build wireinject
// +build wireinject

package app

import (
	"github.com/go-chi/chi/v5"
	"github.com/google/wire"
	"github.com/harehare/textusm/internal/app/handler"
	"github.com/harehare/textusm/internal/config"
	"github.com/harehare/textusm/internal/domain/service"
	"github.com/harehare/textusm/internal/github"
	itemRepo "github.com/harehare/textusm/internal/infra/firebase/item"
	settingsRepo "github.com/harehare/textusm/internal/infra/firebase/settings"
	shareRepo "github.com/harehare/textusm/internal/infra/firebase/share"
	userRepo "github.com/harehare/textusm/internal/infra/firebase/user"
	"github.com/harehare/textusm/internal/presentation/api"
	resolver "github.com/harehare/textusm/internal/presentation/graphql"
)

func provideGithubClientID(env *config.Env) github.ClientID {
	return github.ClientID(env.GithubClientID)
}

func provideGithubClientSecret(env *config.Env) github.ClientSecret {
	return github.ClientSecret(env.GithubClientSecret)
}

func InitializeHandler() (*chi.Mux, error) {
	wire.Build(
		config.Set,
		provideGithubClientID,
		provideGithubClientSecret,
		itemRepo.NewFirestoreItemRepository,
		itemRepo.NewFirestoreGistItemRepository,
		settingsRepo.NewFirestoreSettingsRepository,
		shareRepo.NewFirestoreShareRepository,
		userRepo.NewFirebaseUserRepository,
		service.NewService,
		service.NewGistService,
		service.NewSettingsService,
		resolver.New,
		api.New,
		handler.NewHandler,
	)
	return &chi.Mux{}, nil
}
