package api

import (
	"encoding/json"
	"io"
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
	api := Api{gistService: gistService, settingsService: settingsService}
	return &api
}

type AccessToken struct {
	AccessToken string `json:"access_token"`
}

func (a *Api) RevokeGistToken(w http.ResponseWriter, r *http.Request) {
	body, err := io.ReadAll(r.Body)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	bytes := []byte(body)
	var accessToken AccessToken
	err = json.Unmarshal(bytes, &accessToken)

	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	err = a.service.RevokeGistToken(r.Context(), accessToken.AccessToken)

	if err != nil {
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
