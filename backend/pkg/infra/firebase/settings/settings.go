package settings

import (
	"context"

	"cloud.google.com/go/firestore"
	"github.com/harehare/textusm/pkg/domain/model/settings"
	settingsModel "github.com/harehare/textusm/pkg/domain/model/settings"
	settingsRepo "github.com/harehare/textusm/pkg/domain/repository/settings"
	"github.com/harehare/textusm/pkg/domain/values"
	e "github.com/harehare/textusm/pkg/error"
	"github.com/samber/mo"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

const (
	usersCollection    = "users"
	settingsCollection = "settings"
)

type FirestoreSettingsRepository struct {
	client *firestore.Client
}

func NewFirestoreSettingsRepository(client *firestore.Client) settingsRepo.SettingsRepository {
	return &FirestoreSettingsRepository{client: client}
}

func (r *FirestoreSettingsRepository) Find(ctx context.Context, userID string, diagram values.Diagram) mo.Result[*settings.Settings] {
	fields, err := r.client.Collection(usersCollection).Doc(userID).Collection(settingsCollection).Doc(diagram.String()).Get(ctx)

	if st, ok := status.FromError(err); ok && st.Code() == codes.NotFound {
		return mo.Err[*settings.Settings](e.NotFoundError(err))
	}

	if err != nil {
		return mo.Err[*settings.Settings](err)
	}

	var s settingsModel.Settings
	if err := fields.DataTo(&s); err != nil {
		return mo.Err[*settings.Settings](err)
	}

	return mo.Ok(&s)
}

func (r *FirestoreSettingsRepository) Save(ctx context.Context, userID string, diagram values.Diagram, s settings.Settings) mo.Result[*settings.Settings] {
	_, err := r.client.Collection(usersCollection).Doc(userID).Collection(settingsCollection).Doc(diagram.String()).Set(ctx, s)

	if err != nil {
		return mo.Err[*settings.Settings](err)
	}

	return mo.Ok(&s)
}
