package item

import (
	"context"

	"github.com/harehare/textusm/pkg/domain/model/settings"
	"github.com/harehare/textusm/pkg/domain/values"
)

type SettingsRepository interface {
	Find(ctx context.Context, userID string, diagram values.Diagram) (*settings.Settings, error)
	Save(ctx context.Context, userID string, diagram values.Diagram, settings settings.Settings) (*settings.Settings, error)
}
