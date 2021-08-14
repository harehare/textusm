package api

import (
	"encoding/json"
	"io"
	"net/http"

	"github.com/harehare/textusm/pkg/domain/service"
)

type Api struct {
	gistService service.GistService
}

func New(gistService service.GistService) *Api {
	api := Api{gistService: gistService}
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
