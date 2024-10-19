// Code generated by Wire. DO NOT EDIT.

//go:generate go run -mod=mod github.com/google/wire/cmd/wire
//go:build !wireinject
// +build !wireinject

package app

import (
	"github.com/harehare/textusm/internal/app/handler"
	"github.com/harehare/textusm/internal/app/server"
	"github.com/harehare/textusm/internal/config"
	"github.com/harehare/textusm/internal/db"
	"github.com/harehare/textusm/internal/domain/service"
	"github.com/harehare/textusm/internal/github"
	"github.com/harehare/textusm/internal/infra/firebase/item"
	"github.com/harehare/textusm/internal/infra/firebase/settings"
	"github.com/harehare/textusm/internal/infra/firebase/share"
	"github.com/harehare/textusm/internal/infra/firebase/user"
	item2 "github.com/harehare/textusm/internal/infra/postgres/item"
	settings2 "github.com/harehare/textusm/internal/infra/postgres/settings"
	share2 "github.com/harehare/textusm/internal/infra/postgres/share"
	"github.com/harehare/textusm/internal/presentation/api"
	"github.com/harehare/textusm/internal/presentation/graphql"
	"net/http"
)

// Injectors from wire.go:

func InitializeFirebaseServer() (*http.Server, func(), error) {
	env, err := config.NewEnv()
	if err != nil {
		return nil, nil, err
	}
	configConfig, err := config.NewConfig(env)
	if err != nil {
		return nil, nil, err
	}
	itemRepository := item.NewFirestoreItemRepository(configConfig)
	shareRepository := share.NewFirestoreShareRepository(configConfig)
	userRepository := user.NewFirebaseUserRepository(configConfig)
	transaction := db.NewFirestoreTx(configConfig)
	clientID := provideGithubClientID(env)
	clientSecret := provideGithubClientSecret(env)
	serviceService := service.NewService(itemRepository, shareRepository, userRepository, transaction, clientID, clientSecret)
	gistItemRepository := item.NewFirestoreGistItemRepository(configConfig)
	gistService := service.NewGistService(gistItemRepository, clientID, clientSecret)
	settingsRepository := settings.NewFirestoreSettingsRepository(configConfig)
	settingsService := service.NewSettingsService(settingsRepository, clientID, clientSecret)
	resolver := graphql.New(serviceService, gistService, settingsService, configConfig)
	apiApi := api.New(serviceService, gistService, settingsService)
	logger := config.NewLogger(env)
	mux, err := handler.NewHandler(env, configConfig, resolver, apiApi, logger)
	if err != nil {
		return nil, nil, err
	}
	httpServer, cleanup := server.NewServer(mux, env, configConfig)
	return httpServer, func() {
		cleanup()
	}, nil
}

func InitializePostgresServer() (*http.Server, func(), error) {
	env, err := config.NewEnv()
	if err != nil {
		return nil, nil, err
	}
	configConfig, err := config.NewConfig(env)
	if err != nil {
		return nil, nil, err
	}
	itemRepository := item2.NewPostgresItemRepository(configConfig)
	shareRepository := share2.NewPostgresShareRepository(configConfig)
	userRepository := user.NewFirebaseUserRepository(configConfig)
	transaction := db.NewPostgresTx(configConfig)
	clientID := provideGithubClientID(env)
	clientSecret := provideGithubClientSecret(env)
	serviceService := service.NewService(itemRepository, shareRepository, userRepository, transaction, clientID, clientSecret)
	gistItemRepository := item2.NewPostgresGistItemRepository(configConfig)
	gistService := service.NewGistService(gistItemRepository, clientID, clientSecret)
	settingsRepository := settings2.NewPostgresSettingsRepository(configConfig)
	settingsService := service.NewSettingsService(settingsRepository, clientID, clientSecret)
	resolver := graphql.New(serviceService, gistService, settingsService, configConfig)
	apiApi := api.New(serviceService, gistService, settingsService)
	logger := config.NewLogger(env)
	mux, err := handler.NewHandler(env, configConfig, resolver, apiApi, logger)
	if err != nil {
		return nil, nil, err
	}
	httpServer, cleanup := server.NewServer(mux, env, configConfig)
	return httpServer, func() {
		cleanup()
	}, nil
}

// wire.go:

func provideGithubClientID(env *config.Env) github.ClientID {
	return github.ClientID(env.GithubClientID)
}

func provideGithubClientSecret(env *config.Env) github.ClientSecret {
	return github.ClientSecret(env.GithubClientSecret)
}
