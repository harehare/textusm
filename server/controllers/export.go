package controllers

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"

	"github.com/harehare/textusm/export"
	"github.com/harehare/textusm/models"
	"github.com/mrjones/oauth"
)

var tokens map[string]*oauth.RequestToken

func RedirectUserToTrello(host string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if tokens == nil {
			tokens = make(map[string]*oauth.RequestToken)
		}

		tokenURL := fmt.Sprintf("%s/callback", host)
		trelloConsumer := export.NewTrelloConsumer()
		token, requestURL, err := trelloConsumer.GetRequestTokenAndUrl(tokenURL)
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
		tokens[token.Token] = token
		http.Redirect(w, r, requestURL, http.StatusTemporaryRedirect)
	}
}

func CreateGithubIssues(w http.ResponseWriter, r *http.Request) {
	data, err := getUsmData(r.Body)

	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	exporter := export.NewGithubExporter(data)
	export.Export(data, exporter, w, r)
}

func CreateTrelloBoard(w http.ResponseWriter, r *http.Request) {
	data, err := getUsmData(r.Body)

	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	exporter := export.NewTrelloExporter(data, tokens)
	export.Export(data, exporter, w, r)
}

func getUsmData(body io.Reader) (*models.UsmData, error) {
	var data models.UsmData
	bufbody := new(bytes.Buffer)
	bufbody.ReadFrom(body)
	err := json.Unmarshal(bufbody.Bytes(), &data)

	if err != nil {
		return nil, err
	}

	return &data, nil
}
