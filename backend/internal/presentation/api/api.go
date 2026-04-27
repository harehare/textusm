package api

import (
	"encoding/json"
	"io"
	"log/slog"
	"net/http"

	"github.com/harehare/textusm/internal/domain/service/diagramitem"
	"github.com/harehare/textusm/internal/domain/service/gistitem"
	"github.com/harehare/textusm/internal/domain/service/settings"
)

type Api struct {
	service         *diagramitem.Service
	gistService     *gistitem.Service
	settingsService *settings.Service
}

func New(service *diagramitem.Service, gistService *gistitem.Service, settingsService *settings.Service) *Api {
	return &Api{
		service:         service,
		gistService:     gistService,
		settingsService: settingsService,
	}
}

type AccessToken struct {
	AccessToken string `json:"access_token"`
}

func (a *Api) RevokeGistToken(w http.ResponseWriter, r *http.Request) {
	body, err := io.ReadAll(r.Body)
	if err != nil {
		slog.Error("failed to read request body", "error", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	var accessToken AccessToken
	if err := json.Unmarshal(body, &accessToken); err != nil {
		slog.Warn("failed to unmarshal access token", "error", err)
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	if err := a.service.RevokeGistToken(r.Context(), accessToken.AccessToken); err != nil {
		slog.Error("failed to revoke gist token", "error", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
}

func (a *Api) RevokeToken(w http.ResponseWriter, r *http.Request) {
	err := a.service.RevokeToken(r.Context())

	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
}
