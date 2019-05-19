package main

import (
	"context"
	"fmt"

	"github.com/mrjones/oauth"
)

type TrelloExporter struct {
	client      *Trello
	board       *Board
	lists       map[string]*List
	labelColors []string
	labelIndex  int
}

func NewTrelloExporter(data *UsmData, consumer *oauth.Consumer, tokens map[string]*oauth.RequestToken) *TrelloExporter {
	verificationCode := data.OauthVerifier
	tokenKey := data.OauthToken

	if _, ok := tokens[tokenKey]; !ok {
		return nil
	}

	accessToken, err := trelloConsumer.AuthorizeToken(tokens[tokenKey], verificationCode)
	if err != nil {
		return nil
	}

	client := NewTrello(trelloConsumer, accessToken)

	return &TrelloExporter{
		client:      client,
		lists:       map[string]*List{},
		labelColors: []string{"yellow", "purple", "blue", "red", "green", "orange", "black", "sky", "pink", "lime"},
		labelIndex:  0,
	}
}

func (e *TrelloExporter) CreateProject(ctx context.Context, data *UsmData) error {
	board, err := e.client.CreateBoard(data.Name)
	e.board = board
	return err
}

func (e *TrelloExporter) CreateList(ctx context.Context, data *UsmData, release Release) error {
	list, err := e.board.CreateList(release.Name)
	e.lists[release.Name] = list
	return err
}

func (e *TrelloExporter) CreateCard(ctx context.Context, data *UsmData, task Task) error {
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

		err = card.AddCommentToCard(story.Comment)

		if err != nil {
			return err
		}
	}

	return nil
}

func (e *TrelloExporter) CreateURL(data *UsmData) string {
	return "https://trello.com/b/" + e.board.ID
}
