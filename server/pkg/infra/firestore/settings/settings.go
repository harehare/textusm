package settings

import (
	"context"

	"cloud.google.com/go/firestore"
	"github.com/harehare/textusm/pkg/domain/model/settings"
	settingsModel "github.com/harehare/textusm/pkg/domain/model/settings"
	settingsRepo "github.com/harehare/textusm/pkg/domain/repository/settings"
	"github.com/harehare/textusm/pkg/domain/values"
	e "github.com/harehare/textusm/pkg/error"
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

func (r *FirestoreSettingsRepository) Find(ctx context.Context, userID string, diagram values.Diagram) (*settings.Settings, error) {
	fields, err := r.client.Collection(usersCollection).Doc(userID).Collection(settingsCollection).Doc(diagram.String()).Get(ctx)

	if st, ok := status.FromError(err); ok && st.Code() == codes.NotFound {
		return nil, e.NotFoundError(err)
	}

	if err != nil {
		return nil, err
	}

	var s settingsModel.Settings
	if err := fields.DataTo(&s); err != nil {
		return nil, err
	}

	return &s, nil
}

func (r *FirestoreSettingsRepository) Save(ctx context.Context, userID string, diagram values.Diagram, settings settings.Settings) (*settings.Settings, error) {
	_, err := r.client.Collection(usersCollection).Doc(userID).Collection(settingsCollection).Doc(diagram.String()).Set(ctx, settings)

	if err != nil {
		return nil, err
	}

	return &settings, nil
}
