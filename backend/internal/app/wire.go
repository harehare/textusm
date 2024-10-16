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
	firebaseItemRepo "github.com/harehare/textusm/internal/infra/firebase/item"
	firebaseSettingsRepo "github.com/harehare/textusm/internal/infra/firebase/settings"
	firebaseShareRepo "github.com/harehare/textusm/internal/infra/firebase/share"
	userRepo "github.com/harehare/textusm/internal/infra/firebase/user"
	postgresItemRepo "github.com/harehare/textusm/internal/infra/postgres/item"
	postgresSettingsRepo "github.com/harehare/textusm/internal/infra/postgres/settings"
	postgresShareRepo "github.com/harehare/textusm/internal/infra/postgres/share"
	"github.com/harehare/textusm/internal/presentation/api"
	resolver "github.com/harehare/textusm/internal/presentation/graphql"
)

func provideGithubClientID(env *config.Env) github.ClientID {
	return github.ClientID(env.GithubClientID)
}

func provideGithubClientSecret(env *config.Env) github.ClientSecret {
	return github.ClientSecret(env.GithubClientSecret)
}

func InitializeFirebaseServer() (*http.Server, func(), error) {
	wire.Build(
		config.Set,
		provideGithubClientID,
		provideGithubClientSecret,
		firebaseItemRepo.NewFirestoreItemRepository,
		firebaseItemRepo.NewFirestoreGistItemRepository,
		firebaseSettingsRepo.NewFirestoreSettingsRepository,
		firebaseShareRepo.NewFirestoreShareRepository,
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

func InitializePostgresServer() (*http.Server, func(), error) {
	wire.Build(
		config.Set,
		provideGithubClientID,
		provideGithubClientSecret,
		postgresItemRepo.NewPostgresItemRepository,
		postgresItemRepo.NewPostgresGistItemRepository,
		postgresSettingsRepo.NewPostgresSettingsRepository,
		postgresShareRepo.NewPostgresShareRepository,
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
