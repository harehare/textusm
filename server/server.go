package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"

	"github.com/kelseyhightower/envconfig"
	"github.com/mrjones/oauth"
)

type Env struct {
	Host                 string `envconfig:"API_HOST"`
	Port                 string `envconfig:"PORT"`
	TrelloConsumerKey    string `envconfig:"TRELLO_API_KEY"`
	TrelloConsumerSecret string `envconfig:"TRELLO_API_SECRET"`
}

type UsmData struct {
	OauthToken string    `json:"oauth_token"`
	Name       string    `json:"name"`
	Releases   []Release `json:"releases"`
	Tasks      []Task    `json:"tasks"`

	OauthVerifier string `json:"oauth_verifier,omitempty"`

	Github Github `json:"github,omitempty"`
}

type Github struct {
	Owner string `json:"owner"`
	Repo  string `json:"repo"`
}

type Release struct {
	Name   string `json:"name"`
	Period string `json:"period"`
}

type Task struct {
	Name    string  `json:"name"`
	Comment string  `json:"comment"`
	Stories []Story `json:"stories"`
}

type Story struct {
	Name    string `json:"name"`
	Comment string `json:"comment"`
	Release int    `json:"release"`
}

type Response struct {
	Total      int    `json:"total"`
	Failed     int    `json:"failed"`
	Successful int    `json:"successful"`
	Url        string `json:"url"`
}

var (
	tokens         map[string]*oauth.RequestToken
	trelloConsumer *oauth.Consumer
	env            Env
)

func Start() {
	tokens = make(map[string]*oauth.RequestToken)
	envconfig.Process("TextUSM", &env)

	trelloConsumer = oauth.NewConsumer(
		env.TrelloConsumerKey,
		env.TrelloConsumerSecret,
		oauth.ServiceProvider{
			RequestTokenUrl:   "https://trello.com/1/OAuthGetRequestToken",
			AuthorizeTokenUrl: "https://trello.com/1/OAuthAuthorizeToken",
			AccessTokenUrl:    "https://trello.com/1/OAuthGetAccessToken",
		},
	)
	trelloConsumer.AdditionalAuthorizationUrlParams["name"] = "TextUSM"
	trelloConsumer.AdditionalAuthorizationUrlParams["expiration"] = "1day"
	trelloConsumer.AdditionalAuthorizationUrlParams["scope"] = "read,write"

	http.HandleFunc("/auth/trello", redirectUserToTrello)
	http.HandleFunc("/create/trello", createTrelloBoard)
	http.HandleFunc("/create/github", createGithubIssues)
	u := fmt.Sprintf(":%s", env.Port)

	fmt.Printf("Listening on '%s'\n", u)
	http.ListenAndServe(u, nil)
}

func redirectUserToTrello(w http.ResponseWriter, r *http.Request) {
	tokenURL := fmt.Sprintf("%s/callback", env.Host)
	token, requestURL, err := trelloConsumer.GetRequestTokenAndUrl(tokenURL)
	if err != nil {
		log.Fatal(err)
	}
	tokens[token.Token] = token
	http.Redirect(w, r, requestURL, http.StatusTemporaryRedirect)
}

func setResult(res *Response, err error) {
	if err != nil {
		log.Println(err)
		res.Failed++
	} else {
		res.Successful++
	}
	res.Total++
}

func getUsmData(body io.Reader) (*UsmData, error) {
	var data UsmData
	bufbody := new(bytes.Buffer)
	bufbody.ReadFrom(body)
	err := json.Unmarshal(bufbody.Bytes(), &data)

	if err != nil {
		return nil, err
	}

	return &data, nil
}

func createGithubIssues(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept")
	w.Header().Set("Access-Control-Request-Methods", "POST")

	if r.Method == "OPTIONS" {
		w.WriteHeader(200)
		return
	}

	data, err := getUsmData(r.Body)

	if err != nil {
		log.Println(err)
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	exporter := NewGithubExporter(data)
	Export(data, exporter, w, r)
}

func createTrelloBoard(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept")
	w.Header().Set("Access-Control-Request-Methods", "POST")

	if r.Method == "OPTIONS" {
		w.WriteHeader(200)
		return
	}

	// TODO: Period
	data, err := getUsmData(r.Body)

	if err != nil {
		log.Println(err)
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	exporter := NewTrelloExporter(data, trelloConsumer, tokens)
	Export(data, exporter, w, r)
}
