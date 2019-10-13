package export

import (
	"context"
	"fmt"

	"github.com/harehare/textusm/server/models"
	"github.com/harehare/textusm/server/trello"
	"github.com/kelseyhightower/envconfig"
	"github.com/mrjones/oauth"
)

type TrelloExporter struct {
	client      *trello.Trello
	board       *trello.Board
	lists       map[string]*trello.List
	labelColors []string
	labelIndex  int
}

type Env struct {
	TrelloConsumerKey    string `envconfig:"TRELLO_API_KEY"`
	TrelloConsumerSecret string `envconfig:"TRELLO_API_SECRET"`
}

func NewTrelloConsumer() *oauth.Consumer {
	var env Env
	envconfig.Process("TextUSM", &env)

	trelloConsumer := oauth.NewConsumer(
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

	return trelloConsumer
}

func NewTrelloExporter(data *models.UsmData, tokens map[string]*oauth.RequestToken) *TrelloExporter {
	verificationCode := data.OauthVerifier
	tokenKey := data.OauthToken

	if _, ok := tokens[tokenKey]; !ok {
		return nil
	}

	trelloConsumer := NewTrelloConsumer()

	accessToken, err := trelloConsumer.AuthorizeToken(tokens[tokenKey], verificationCode)
	if err != nil {
		return nil
	}

	client := trello.NewTrello(trelloConsumer, accessToken)

	return &TrelloExporter{
		client:      client,
		lists:       map[string]*trello.List{},
		labelColors: []string{"yellow", "purple", "blue", "red", "green", "orange", "black", "sky", "pink", "lime"},
		labelIndex:  0,
	}
}

func (e *TrelloExporter) CreateProject(ctx context.Context, data *models.UsmData) error {
	board, err := e.client.CreateBoard(data.Name)
	e.board = board
	return err
}

func (e *TrelloExporter) CreateList(ctx context.Context, data *models.UsmData, release models.Release) error {
	list, err := e.board.CreateList(release.Name)
	e.lists[release.Name] = list
	return err
}

func (e *TrelloExporter) CreateCard(ctx context.Context, data *models.UsmData, task models.Task) error {
	if e.labelIndex >= len(e.labelColors) {
		e.labelIndex = 0
	}
	label, err := e.board.AddLabel(task.Name, e.labelColors[e.labelIndex])

	if err != nil {
		return err
	}

	e.labelIndex++

	for _, story := range task.Stories {
		key := fmt.Sprintf("RELEASE%d", story.Release)
		if _, ok := e.lists[key]; !ok {
			continue
		}

		card, err := e.lists[key].CreateCard(story.Name)

		if err != nil {
			return err
		}

		err = card.AddLabelToCard(label.ID)

		if err != nil {
			return err
		}
	}

	return nil
}

func (e *TrelloExporter) CreateURL(data *models.UsmData) string {
	return "https://trello.com/b/" + e.board.ID
}
