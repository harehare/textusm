package settings

import (
	"context"
	"strings"

	"cloud.google.com/go/firestore"
	"firebase.google.com/go/v4/storage"
	"github.com/harehare/textusm/internal/domain/model/settings"
	settingsModel "github.com/harehare/textusm/internal/domain/model/settings"
	settingsRepo "github.com/harehare/textusm/internal/domain/repository/settings"
	"github.com/harehare/textusm/internal/domain/values"
	e "github.com/harehare/textusm/internal/error"
	"github.com/harehare/textusm/internal/infra/firebase"
	"github.com/samber/mo"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

const (
	usersCollection    = "users"
	settingsCollection = "settings"
)

type FirestoreSettingsRepository struct {
	client  *firestore.Client
	storage *storage.Client
}

func NewFirestoreSettingsRepository(client *firestore.Client, storage *storage.Client) settingsRepo.SettingsRepository {
	return &FirestoreSettingsRepository{client: client, storage: storage}
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

func (r *FirestoreSettingsRepository) FindFontList(ctx context.Context, lang string) mo.Result[[]string] {
	storage := firebase.NewCloudStorage(r.storage)
	fontListResult := storage.Get(ctx, "fontlist", "all")

	if fontListResult.IsError() {
		return mo.Err[[]string](fontListResult.Error())
	}

	langFontListResult := storage.Get(ctx, "fontlist", lang + ".txt")

	if langFontListResult.IsError() {
		return mo.Ok(strings.Split(fontListResult.OrEmpty(), "\n"))
	}

	return mo.Ok(append(strings.Split(fontListResult.OrEmpty(), "\n"), strings.Split(langFontListResult.OrEmpty(), "\n")...))
}

func (r *FirestoreSettingsRepository) Save(ctx context.Context, userID string, diagram values.Diagram, s settings.Settings) mo.Result[*settings.Settings] {
	_, err := r.client.Collection(usersCollection).Doc(userID).Collection(settingsCollection).Doc(diagram.String()).Set(ctx, s)

	if err != nil {
		return mo.Err[*settings.Settings](err)
	}

	return mo.Ok(&s)
}
