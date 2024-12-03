//go:generate go install github.com/google/wire/cmd/wire@latest
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
	"github.com/harehare/textusm/internal/domain/service/diagramitem"
	"github.com/harehare/textusm/internal/domain/service/gistitem"
	"github.com/harehare/textusm/internal/domain/service/settings"
	"github.com/harehare/textusm/internal/github"
	"github.com/harehare/textusm/internal/infra/firebase"
	"github.com/harehare/textusm/internal/infra/postgres"
	"github.com/harehare/textusm/internal/infra/sqlite"
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
		db.NewFirestoreTx,
		firebase.NewItemRepository,
		firebase.NewGistItemRepository,
		firebase.NewSettingsRepository,
		firebase.NewShareRepository,
		firebase.NewUserRepository,
		diagramitem.NewService,
		gistitem.NewService,
		settings.NewService,
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
		db.NewPostgresTx,
		postgres.NewItemRepository,
		postgres.NewGistItemRepository,
		postgres.NewSettingsRepository,
		postgres.NewShareRepository,
		firebase.NewUserRepository,
		diagramitem.NewService,
		gistitem.NewService,
		settings.NewService,
		resolver.New,
		api.New,
		handler.NewHandler,
		server.NewServer,
	)
	return &http.Server{}, func() {}, nil
}

func InitializeSqliteServer() (*http.Server, func(), error) {
	wire.Build(
		config.Set,
		provideGithubClientID,
		provideGithubClientSecret,
		db.NewDBTx,
		sqlite.NewItemRepository,
		sqlite.NewGistItemRepository,
		sqlite.NewSettingsRepository,
		sqlite.NewShareRepository,
		firebase.NewUserRepository,
		diagramitem.NewService,
		gistitem.NewService,
		settings.NewService,
		resolver.New,
		api.New,
		handler.NewHandler,
		server.NewServer,
	)
	return &http.Server{}, func() {}, nil
}
