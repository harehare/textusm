package settings

import (
	"context"
	"database/sql"
	"errors"

	"github.com/harehare/textusm/internal/config"
	v "github.com/harehare/textusm/internal/context/values"
	"github.com/harehare/textusm/internal/db/postgres"
	"github.com/harehare/textusm/internal/domain/model/settings"
	settingsRepo "github.com/harehare/textusm/internal/domain/repository/settings"
	"github.com/harehare/textusm/internal/domain/values"
	"github.com/samber/mo"
)

type PostgresSettingsRepository struct {
	_db *postgres.Queries
}

func NewPostgresSettingsRepository(config *config.Config) settingsRepo.SettingsRepository {
	return &PostgresSettingsRepository{_db: postgres.New(config.PostgresConn)}
}

func (r *PostgresSettingsRepository) tx(ctx context.Context) *postgres.Queries {
	tx := v.GetDBTx(ctx)

	if tx.IsPresent() {
		return r._db.WithTx(*tx.MustGet())
	} else {
		return r._db
	}
}

func (r *PostgresSettingsRepository) Find(ctx context.Context, userID string, diagram values.Diagram) mo.Result[*settings.Settings] {
	s, err := r.tx(ctx).GetSettings(ctx, postgres.Diagram(diagram))

	if err != nil {
		return mo.Err[*settings.Settings](err)
	}

	scale := float64(*s.Scale)

	ss := settings.Settings{
		Font:            *s.Font,
		Width:           int(*s.Width),
		Height:          int(*s.Height),
		BackgroundColor: *s.BackgroundColor,
		ActivityColor:   settings.Color{ForegroundColor: *s.ActivityColor, BackgroundColor: *s.ActivityBackgroundColor},
		TaskColor:       settings.Color{ForegroundColor: *s.TaskColor, BackgroundColor: *s.TaskBackgroundColor},
		StoryColor:      settings.Color{ForegroundColor: *s.StoryColor, BackgroundColor: *s.StoryBackgroundColor},
		LineColor:       *s.LineColor,
		LabelColor:      *s.LabelColor,
		TextColor:       s.TextColor,
		ZoomControl:     s.ZoomControl,
		Scale:           &scale,
		Toolbar:         s.Toolbar,
		LockEditing:     s.LockEditing,
		ShowGrid:        s.ShowGrid,
	}

	return mo.Ok(&ss)
}

func (r *PostgresSettingsRepository) Save(ctx context.Context, userID string, diagram values.Diagram, s settings.Settings) mo.Result[*settings.Settings] {
	backgroundColor := s.BackgroundColor
	width := int32(s.Width)
	height := int32(s.Height)
	scale := float32(*s.Scale)

	_, err := r.tx(ctx).GetSettings(ctx, postgres.Diagram(diagram))

	if errors.Is(err, sql.ErrNoRows) {
		err = r.tx(ctx).CreateSettings(ctx, postgres.CreateSettingsParams{
			Uid:                     userID,
			Diagram:                 postgres.Diagram(diagram),
			ActivityColor:           &s.ActivityColor.ForegroundColor,
			ActivityBackgroundColor: &s.ActivityColor.BackgroundColor,
			BackgroundColor:         &backgroundColor,
			Height:                  &height,
			LineColor:               &s.LineColor,
			LabelColor:              &s.LabelColor,
			LockEditing:             s.LockEditing,
			TextColor:               s.TextColor,
			Toolbar:                 s.Toolbar,
			Scale:                   &scale,
			ShowGrid:                s.ShowGrid,
			StoryColor:              &s.StoryColor.ForegroundColor,
			StoryBackgroundColor:    &s.StoryColor.BackgroundColor,
			TaskColor:               &s.TaskColor.ForegroundColor,
			TaskBackgroundColor:     &s.TaskColor.BackgroundColor,
			Width:                   &width,
			ZoomControl:             s.ZoomControl,
		})
	} else if err != nil {
		return mo.Err[*settings.Settings](err)
	} else {
		err = r.tx(ctx).UpdateSettings(ctx, postgres.UpdateSettingsParams{
			ActivityColor:           &s.ActivityColor.ForegroundColor,
			ActivityBackgroundColor: &s.ActivityColor.BackgroundColor,
			BackgroundColor:         &backgroundColor,
			Height:                  &height,
			LineColor:               &s.LineColor,
			LabelColor:              &s.LabelColor,
			LockEditing:             s.LockEditing,
			TextColor:               s.TextColor,
			Toolbar:                 s.Toolbar,
			Scale:                   &scale,
			ShowGrid:                s.ShowGrid,
			StoryColor:              &s.StoryColor.ForegroundColor,
			StoryBackgroundColor:    &s.StoryColor.BackgroundColor,
			TaskColor:               &s.TaskColor.ForegroundColor,
			TaskBackgroundColor:     &s.TaskColor.BackgroundColor,
			Width:                   &width,
			ZoomControl:             s.ZoomControl,
		})
	}

	if err != nil {
		return mo.Err[*settings.Settings](err)
	}

	return mo.Ok(&s)
}
