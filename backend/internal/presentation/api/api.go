package api

import (
	"encoding/json"
	"io"
	"net/http"

	"github.com/harehare/textusm/internal/domain/service"
)

type Api struct {
	gistService     *service.GistService
	settingsService *service.SettingsService
}

func New(gistService *service.GistService, settingsService *service.SettingsService) *Api {
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

	err = a.gistService.RevokeToken(r.Context(), accessToken.AccessToken)

	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
}

func (a *Api) UsableFontList(w http.ResponseWriter, r *http.Request) {
	fontList := a.settingsService.FindFontList(r.Context(), r.URL.Query().Get("lang"))

	if fontList.IsError() {
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	err := json.NewEncoder(w).Encode(fontList.OrElse([]string{}))

	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
}
