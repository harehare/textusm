package textusm

import (
	"context"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/url"
	"strings"
	"time"

	"github.com/mrjones/oauth"
)

const BaseURL = "https://api.trello.com/1"

type Trello struct {
	Client      *oauth.Consumer
	AccessToken *oauth.AccessToken
	throttle    <-chan time.Time
	ctx         context.Context
}

type Board struct {
	client *Trello
	ID     string `json:"id"`
	Name   string `json:"name"`
}

type List struct {
	client *Trello
	ID     string `json:"id"`
	Name   string `json:"name"`
}

type Card struct {
	client *Trello
	ID     string `json:"id"`
	Name   string `json:"name"`
}

type Label struct {
	ID    string `json:"id"`
	Color string `json:"color"`
}

func NewTrello(client *oauth.Consumer, accessToken *oauth.AccessToken) *Trello {
	return &Trello{
		Client:      client,
		AccessToken: accessToken,
		throttle:    time.Tick(time.Second / 10),
		ctx:         context.Background(),
	}
}

func (t *Trello) CreateBoard(name string) (*Board, error) {
	payload := url.Values{}
	payload.Set("name", name)

	var board Board
	err := t.Post("/boards", payload, &board)

	if err != nil {
		// TODO:
	}
	board.client = t

	return &board, err
}

func (b *Board) CreateList(name string) (*List, error) {
	payload := url.Values{}
	payload.Set("name", name)
	payload.Set("idBoard", b.ID)

	var list List
	err := b.client.Post("/lists", payload, &list)

	if err == nil {
		list.client = b.client
	}

	return &list, err
}

func (b *Board) AddLabel(name, color string) (*Label, error) {
	payload := url.Values{}
	payload.Set("name", name)
	payload.Set("idBoard", b.ID)
	payload.Set("color", color)

	var label Label
	err := b.client.Post("/labels", payload, &label)

	return &label, err
}

func (b *Card) AddLabelToCard(labelId string) error {
	path := fmt.Sprintf("/cards/%s/idLabels", b.ID)
	payload := url.Values{}
	payload.Set("value", labelId)

	var label Label
	err := b.client.Post(path, payload, &label)

	return err
}

func (b *Card) AddCommentToCard(text string) error {
	path := fmt.Sprintf("/cards/%s/actions/comments", b.ID)
	payload := url.Values{}
	payload.Set("text", text)

	var label Label
	err := b.client.Post(path, payload, &label)

	return err
}

func (l *List) CreateCard(name string) (*Card, error) {
	payload := url.Values{}
	payload.Set("name", name)
	payload.Set("idList", l.ID)

	var card Card
	err := l.client.Post("/cards", payload, &card)

	if err == nil {
		card.client = l.client
	}

	return &card, err
}

func (t *Trello) Post(path string, data url.Values, target interface{}) error {

	<-t.throttle
	client, err := t.Client.MakeHttpClient(t.AccessToken)
	if err != nil {
		log.Fatal(err)
	}

	url := BaseURL + path
	resp, err := client.Post(url, "application/x-www-form-urlencoded", strings.NewReader(data.Encode()))

	if err != nil {
		// TODO:
	}

	defer resp.Body.Close()

	b, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return err
	}

	err = json.Unmarshal(b, target)

	if err != nil {
		return err
	}

	return nil
}
