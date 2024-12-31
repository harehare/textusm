// Code generated by sqlc. DO NOT EDIT.
// versions:
//   sqlc v1.27.0

package sqlite

import (
	"database/sql"
)

type Item struct {
	ID         int64
	Uid        string
	DiagramID  string
	Location   string
	Diagram    string
	IsBookmark int64
	IsPublic   int64
	Title      sql.NullString
	Text       string
	Thumbnail  sql.NullString
	CreatedAt  int64
	UpdatedAt  int64
}

type SchemaMigrations struct {
	Version string
}

type Setting struct {
	ID                      int64
	Uid                     string
	ActivityColor           string
	ActivityBackgroundColor string
	BackgroundColor         string
	Diagram                 string
	Height                  int64
	Font                    string
	LineColor               string
	LabelColor              string
	LockEditing             sql.NullInt64
	TextColor               sql.NullString
	Toolbar                 sql.NullInt64
	Scale                   float64
	ShowGrid                sql.NullInt64
	StoryColor              string
	StoryBackgroundColor    string
	TaskColor               string
	TaskBackgroundColor     string
	Width                   int64
	ZoomControl             sql.NullInt64
	CreatedAt               int64
	UpdatedAt               int64
}

type ShareCondition struct {
	ID             int64
	Hashkey        string
	Uid            string
	DiagramID      string
	Location       string
	AllowIpList    sql.NullString
	AllowEmailList sql.NullString
	ExpireTime     sql.NullInt64
	Password       sql.NullString
	Token          string
	CreatedAt      int64
	UpdatedAt      int64
}