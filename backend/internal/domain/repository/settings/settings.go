package item

import (
	"context"

	"github.com/harehare/textusm/internal/domain/model/settings"
	"github.com/harehare/textusm/internal/domain/values"
	"github.com/samber/mo"
)

type SettingsRepository interface {
	Find(ctx context.Context, userID string, diagram values.Diagram) mo.Result[*settings.Settings]
	Save(ctx context.Context, userID string, diagram values.Diagram, settings settings.Settings) mo.Result[*settings.Settings]
}
