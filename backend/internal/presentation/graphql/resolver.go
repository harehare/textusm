//go:generate go run github.com/99designs/gqlgen
package graphql

// THIS CODE IS A STARTING POINT ONLY. IT WILL NOT BE UPDATED WITH SCHEMA CHANGES.

import (
	"cloud.google.com/go/firestore"
	"github.com/harehare/textusm/internal/config"
	"github.com/harehare/textusm/internal/domain/service"
)

type Resolver struct {
	service         *service.Service
	gistService     *service.GistService
	settingsService *service.SettingsService
	client          *firestore.Client
}

func New(service *service.Service, gistService *service.GistService, settingsService *service.SettingsService, config *config.Config) *Resolver {
	r := Resolver{service: service, gistService: gistService, settingsService: settingsService, client: config.FirestoreClient}
	return &r
}
