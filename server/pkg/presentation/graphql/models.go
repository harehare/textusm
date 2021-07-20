// Code generated by github.com/99designs/gqlgen, DO NOT EDIT.

package server

import (
	"github.com/harehare/textusm/pkg/domain/values"
)

type InputGistItem struct {
	ID         *values.GistID  `json:"id"`
	Title      string          `json:"title"`
	Thumbnail  *string         `json:"thumbnail"`
	Diagram    *values.Diagram `json:"diagram"`
	IsBookmark bool            `json:"isBookmark"`
	URL        string          `json:"url"`
	Tags       []*string       `json:"tags"`
}

type InputItem struct {
	ID         *values.ItemID  `json:"id"`
	Title      string          `json:"title"`
	Text       string          `json:"text"`
	Thumbnail  *string         `json:"thumbnail"`
	Diagram    *values.Diagram `json:"diagram"`
	IsPublic   bool            `json:"isPublic"`
	IsBookmark bool            `json:"isBookmark"`
	Tags       []*string       `json:"tags"`
}

type InputShareItem struct {
	ItemID         *values.ItemID `json:"itemID"`
	ExpSecond      *int           `json:"expSecond"`
	Password       *string        `json:"password"`
	AllowIPList    []string       `json:"allowIPList"`
	AllowEmailList []string       `json:"allowEmailList"`
}
