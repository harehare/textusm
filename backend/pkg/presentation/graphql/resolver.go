//go:generate go run github.com/99designs/gqlgen
package graphql

// THIS CODE IS A STARTING POINT ONLY. IT WILL NOT BE UPDATED WITH SCHEMA CHANGES.

import (
	"cloud.google.com/go/firestore"
	"github.com/harehare/textusm/pkg/domain/service"
)

type Resolver struct {
	service         *service.Service
	gistService     *service.GistService
	settingsService *service.SettingsService
	client          *firestore.Client
}

func New(service *service.Service, gistService *service.GistService, settingsService *service.SettingsService, client *firestore.Client) *Resolver {
	r := Resolver{service: service, gistService: gistService, settingsService: settingsService, client: client}
	return &r
}
