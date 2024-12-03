//go:generate go run github.com/99designs/gqlgen
package graphql

// THIS CODE IS A STARTING POINT ONLY. IT WILL NOT BE UPDATED WITH SCHEMA CHANGES.

import (
	"github.com/harehare/textusm/internal/config"
	"github.com/harehare/textusm/internal/domain/service/diagramitem"
	"github.com/harehare/textusm/internal/domain/service/gistitem"
	"github.com/harehare/textusm/internal/domain/service/settings"
)

type Resolver struct {
	service         *diagramitem.Service
	gistService     *gistitem.Service
	settingsService *settings.Service
}

func New(service *diagramitem.Service, gistService *gistitem.Service, settingsService *settings.Service, config *config.Config) *Resolver {
	r := Resolver{service: service, gistService: gistService, settingsService: settingsService}
	return &r
}
