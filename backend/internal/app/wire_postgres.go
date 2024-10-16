//go:build wireinject
// +build wireinject

package app

import (
	"net/http"

	"github.com/google/wire"
	"github.com/harehare/textusm/internal/app/handler"
	"github.com/harehare/textusm/internal/app/server"
	"github.com/harehare/textusm/internal/config"
	"github.com/harehare/textusm/internal/db"
	"github.com/harehare/textusm/internal/domain/service"
	"github.com/harehare/textusm/internal/github"
	userRepo "github.com/harehare/textusm/internal/infra/firebase/user"
	itemRepo "github.com/harehare/textusm/internal/infra/postgres/item"
	settingsRepo "github.com/harehare/textusm/internal/infra/postgres/settings"
	shareRepo "github.com/harehare/textusm/internal/infra/postgres/share"
	"github.com/harehare/textusm/internal/presentation/api"
	resolver "github.com/harehare/textusm/internal/presentation/graphql"
)

func provideGithubClientID(env *config.Env) github.ClientID {
	return github.ClientID(env.GithubClientID)
}

func provideGithubClientSecret(env *config.Env) github.ClientSecret {
	return github.ClientSecret(env.GithubClientSecret)
}

func InitializeServer() (*http.Server, func(), error) {
	wire.Build(
		config.Set,
		provideGithubClientID,
		provideGithubClientSecret,
		itemRepo.NewPostgresItemRepository,
		itemRepo.NewPostgresGistItemRepository,
		settingsRepo.NewPostgresSettingsRepository,
		shareRepo.NewPostgresShareRepository,
		userRepo.NewFirebaseUserRepository,
		service.NewService,
		service.NewGistService,
		service.NewSettingsService,
		db.NewFirestoreTx,
		resolver.New,
		api.New,
		handler.NewHandler,
		server.NewServer,
	)
	return &http.Server{}, func() {}, nil
}
