package settings

import (
	"context"
	"database/sql"
	"errors"
	"time"

	"github.com/harehare/textusm/internal/config"
	v "github.com/harehare/textusm/internal/context/values"
	"github.com/harehare/textusm/internal/db/sqlite"
	"github.com/harehare/textusm/internal/domain/model/settings"
	settingsRepo "github.com/harehare/textusm/internal/domain/repository/settings"
	"github.com/harehare/textusm/internal/domain/values"
	db "github.com/harehare/textusm/internal/infra/sqlite"
	"github.com/samber/mo"
)

type SqliteSettingsRepository struct {
	_db *sqlite.Queries
}

func NewSqliteSettingsRepository(config *config.Config) settingsRepo.SettingsRepository {
	return &SqliteSettingsRepository{_db: sqlite.New(config.SqlConn)}
}

func (r *SqliteSettingsRepository) tx(ctx context.Context) *sqlite.Queries {
	tx := v.GetDBTx(ctx)

	if tx.IsPresent() {
		return r._db.WithTx(tx.MustGet())
	} else {
		return r._db
	}
}

func (r *SqliteSettingsRepository) Find(ctx context.Context, userID string, diagram values.Diagram) mo.Result[*settings.Settings] {
	s, err := r.tx(ctx).GetSettings(ctx, sqlite.GetSettingsParams{Uid: userID, Diagram: string(diagram)})

	if err != nil {
		return mo.Err[*settings.Settings](err)
	}

	scale := float64(s.Scale)

	ss := settings.Settings{
		Font:            s.Font,
		Width:           int(s.Width),
		Height:          int(s.Height),
		BackgroundColor: s.BackgroundColor,
		ActivityColor:   settings.Color{ForegroundColor: s.ActivityColor, BackgroundColor: s.ActivityBackgroundColor},
		TaskColor:       settings.Color{ForegroundColor: s.TaskColor, BackgroundColor: s.TaskBackgroundColor},
		StoryColor:      settings.Color{ForegroundColor: s.StoryColor, BackgroundColor: s.StoryBackgroundColor},
		LineColor:       s.LineColor,
		LabelColor:      s.LabelColor,
		TextColor:       db.NullStringToString(s.TextColor),
		ZoomControl:     db.NullIntToBool(s.ZoomControl),
		Scale:           &scale,
		Toolbar:         db.NullIntToBool(s.Toolbar),
		LockEditing:     db.NullIntToBool(s.LockEditing),
		ShowGrid:        db.NullIntToBool(s.ShowGrid),
	}

	return mo.Ok(&ss)
}

func (r *SqliteSettingsRepository) Save(ctx context.Context, userID string, diagram values.Diagram, s settings.Settings) mo.Result[*settings.Settings] {
	backgroundColor := s.BackgroundColor
	width := int32(s.Width)
	height := int32(s.Height)
	scale := float32(*s.Scale)

	_, err := r.tx(ctx).GetSettings(ctx, sqlite.GetSettingsParams{Uid: userID, Diagram: string(diagram)})

	if errors.Is(err, sql.ErrNoRows) {
		err = r.tx(ctx).CreateSettings(ctx, sqlite.CreateSettingsParams{
			Uid:                     userID,
			Diagram:                 string(diagram),
			ActivityColor:           s.ActivityColor.ForegroundColor,
			ActivityBackgroundColor: s.ActivityColor.BackgroundColor,
			BackgroundColor:         backgroundColor,
			Height:                  int64(height),
			LineColor:               s.LineColor,
			LabelColor:              s.LabelColor,
			LockEditing:             db.BoolToNullInt(s.LockEditing),
			TextColor:               db.StringToNullString(s.TextColor),
			Toolbar:                 db.BoolToNullInt(s.Toolbar),
			Scale:                   float64(scale),
			ShowGrid:                db.BoolToNullInt(s.ShowGrid),
			StoryColor:              s.StoryColor.ForegroundColor,
			StoryBackgroundColor:    s.StoryColor.BackgroundColor,
			TaskColor:               s.TaskColor.ForegroundColor,
			TaskBackgroundColor:     s.TaskColor.BackgroundColor,
			Width:                   int64(width),
			ZoomControl:             db.BoolToNullInt(s.ZoomControl),
			CreatedAt:               db.DateTimeToInt(time.Now()),
			UpdatedAt:               db.DateTimeToInt(time.Now()),
		})
	} else if err != nil {
		return mo.Err[*settings.Settings](err)
	} else {
		err = r.tx(ctx).UpdateSettings(ctx, sqlite.UpdateSettingsParams{
			Uid:                     userID,
			ActivityColor:           s.ActivityColor.ForegroundColor,
			ActivityBackgroundColor: s.ActivityColor.BackgroundColor,
			BackgroundColor:         backgroundColor,
			Height:                  int64(height),
			LineColor:               s.LineColor,
			LabelColor:              s.LabelColor,
			LockEditing:             db.BoolToNullInt(s.LockEditing),
			TextColor:               db.StringToNullString(s.TextColor),
			Toolbar:                 db.BoolToNullInt(s.Toolbar),
			Scale:                   float64(scale),
			ShowGrid:                db.BoolToNullInt(s.ShowGrid),
			StoryColor:              s.StoryColor.ForegroundColor,
			StoryBackgroundColor:    s.StoryColor.BackgroundColor,
			TaskColor:               s.TaskColor.ForegroundColor,
			TaskBackgroundColor:     s.TaskColor.BackgroundColor,
			Width:                   int64(width),
			ZoomControl:             db.BoolToNullInt(s.ZoomControl),
			UpdatedAt:               db.DateTimeToInt(time.Now()),
		})
	}

	if err != nil {
		return mo.Err[*settings.Settings](err)
	}

	return mo.Ok(&s)
}
