package textusm

import (
	"bytes"
	"encoding/json"
	"fmt"
	"log"
	"net/http"

	"github.com/kelseyhightower/envconfig"
	"github.com/mrjones/oauth"
)

type TrelloEnv struct {
	Host           string `envconfig:"API_HOST"`
	ConsumerKey    string `envconfig:"API_KEY"`
	ConsumerSecret string `envconfig:"API_SECRET"`
	Port           string `envconfig:"PORT"`
}

type UsmData struct {
	OauthVerifier string `json:"oauth_verifier"`
	OauthToken    string `json:"oauth_token"`
	Name          string `json:"name"`
	ReleaseCount  int    `json:"release"`
	Tasks         []Task `json:"tasks"`
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
	tokens map[string]*oauth.RequestToken
	c      *oauth.Consumer
	env    TrelloEnv
)

func Start() {
	tokens = make(map[string]*oauth.RequestToken)
	envconfig.Process("TextUSM", &env)

	c = oauth.NewConsumer(
		env.ConsumerKey,
		env.ConsumerSecret,
		oauth.ServiceProvider{
			RequestTokenUrl:   "https://trello.com/1/OAuthGetRequestToken",
			AuthorizeTokenUrl: "https://trello.com/1/OAuthAuthorizeToken",
			AccessTokenUrl:    "https://trello.com/1/OAuthGetAccessToken",
		},
	)
	c.AdditionalAuthorizationUrlParams["name"] = "TextUSM"
	c.AdditionalAuthorizationUrlParams["expiration"] = "1day"
	c.AdditionalAuthorizationUrlParams["scope"] = "read,write"

	http.HandleFunc("/auth/trello", redirectUserToTrello)
	http.HandleFunc("/create/trello", createTrelloBoard)
	u := fmt.Sprintf(":%s", env.Port)

	fmt.Printf("Listening on '%s'\n", u)
	http.ListenAndServe(u, nil)
}

func redirectUserToTrello(w http.ResponseWriter, r *http.Request) {

	tokenURL := fmt.Sprintf("%s/callback", env.Host)
	token, requestURL, err := c.GetRequestTokenAndUrl(tokenURL)
	if err != nil {
		log.Fatal(err)
	}
	tokens[token.Token] = token
	http.Redirect(w, r, requestURL, http.StatusTemporaryRedirect)
}

func createTrelloBoard(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept")
	w.Header().Set("Access-Control-Request-Methods", "POST")

	if r.Method == "OPTIONS" {
		w.WriteHeader(200)
		return
	}

	res := Response{Total: 0, Failed: 0, Successful: 0}
	bufbody := new(bytes.Buffer)
	bufbody.ReadFrom(r.Body)

	var usmData UsmData
	err := json.Unmarshal(bufbody.Bytes(), &usmData)

	if err != nil {
		log.Println(err)
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	verificationCode := usmData.OauthVerifier
	tokenKey := usmData.OauthToken

	if _, ok := tokens[tokenKey]; !ok {
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	accessToken, err := c.AuthorizeToken(tokens[tokenKey], verificationCode)
	if err != nil {
		log.Println(err)
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	client := NewTrello(c, accessToken)

	board, err := client.CreateBoard(usmData.Name)

	if err != nil {
		log.Println(err)
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	lists := map[int]*List{}

	for i := 0; i < usmData.ReleaseCount; i++ {
		list, err := board.CreateList(fmt.Sprintf("RELEASE%d", i+1))

		if err != nil {
			log.Println(err)
			res.Failed++
		} else {
			res.Successful++
		}
		res.Total++

		lists[i+1] = list
	}

	labelColors := []string{"yellow", "purple", "blue", "red", "green", "orange", "black", "sky", "pink", "lime"}
	labelIndex := 0

	for _, task := range usmData.Tasks {
		if labelIndex >= len(labelColors) {
			labelIndex = 0
		}
		label, err := board.AddLabel(task.Name, labelColors[labelIndex])
		labelIndex++

		if err != nil {
			log.Println(err)
			res.Failed++
		} else {
			res.Successful++
		}
		res.Total++

		for _, story := range task.Stories {

			if _, ok := lists[story.Release]; !ok {
				continue
			}

			card, err := lists[story.Release].CreateCard(story.Name)
			if err != nil {
				log.Println(err)
				res.Failed++
			} else {
				res.Successful++
			}
			res.Total++

			err = card.AddLabelToCard(label.ID)

			if err != nil {
				log.Println(err)
				res.Failed++
			} else {
				res.Successful++
			}
			res.Total++

			err = card.AddCommentToCard(story.Comment)

			if err != nil {
				log.Println(err)
				res.Failed++
			} else {
				res.Successful++
			}
			res.Total++
		}
	}

	res.Url = "https://trello.com/b/" + board.ID
	b, err := json.Marshal(res)

	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
	} else {
		w.Write(b)
	}
}
