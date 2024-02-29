package settings

import (
	"context"
	"log/slog"
	"strings"
	"time"

	"github.com/samber/lo"

	"cloud.google.com/go/firestore"
	"firebase.google.com/go/v4/storage"
	"github.com/harehare/textusm/internal/domain/model/settings"
	settingsRepo "github.com/harehare/textusm/internal/domain/repository/settings"
	"github.com/harehare/textusm/internal/domain/values"
	e "github.com/harehare/textusm/internal/error"
	"github.com/harehare/textusm/internal/infra/firebase"
	"github.com/redis/go-redis/v9"
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
	redis   *redis.Client
}

func NewFirestoreSettingsRepository(client *firestore.Client, storage *storage.Client, redis *redis.Client) settingsRepo.SettingsRepository {
	return &FirestoreSettingsRepository{client: client, storage: storage, redis: redis}
}

func (r *FirestoreSettingsRepository) Find(ctx context.Context, userID string, diagram values.Diagram) mo.Result[*settings.Settings] {
	fields, err := r.client.Collection(usersCollection).Doc(userID).Collection(settingsCollection).Doc(diagram.String()).Get(ctx)

	if st, ok := status.FromError(err); ok && st.Code() == codes.NotFound {
		return mo.Err[*settings.Settings](e.NotFoundError(err))
	}

	if err != nil {
		return mo.Err[*settings.Settings](err)
	}

	var s settings.Settings
	if err := fields.DataTo(&s); err != nil {
		return mo.Err[*settings.Settings](err)
	}

	return mo.Ok(&s)
}

func (r *FirestoreSettingsRepository) FindFontList(ctx context.Context, lang string) mo.Result[[]string] {
	cacheKey := "fontlist_" + lang

	if r.redis != nil {
		cachedFontList, err := r.redis.Get(ctx, cacheKey).Result()

		if (err == nil || err != redis.Nil) && cachedFontList != "" {
			return mo.Ok(lo.Filter(strings.Split(cachedFontList, "\n"), func(x string, index int) bool {
				return x != ""
			}))
		}
	}

	storage := firebase.NewCloudStorage(r.storage)
	fontListResult := storage.Get(ctx, "fontlist", "all")

	if fontListResult.IsError() {
		return mo.Err[[]string](fontListResult.Error())
	}

	langFontListResult := storage.Get(ctx, "fontlist", lang)

	if langFontListResult.IsError() {
		return mo.Ok(strings.Split(fontListResult.OrEmpty(), "\n"))
	}

	fontList := append(strings.Split(fontListResult.OrEmpty(), "\n"), strings.Split(langFontListResult.OrEmpty(), "\n")...)

	if r.redis != nil {
		_, err := r.redis.Pipelined(ctx, func(pipe redis.Pipeliner) error {
			err := pipe.Set(ctx, cacheKey, strings.Join(fontList, "\n"), 0).Err()

			if err != nil {
				return err
			}

			err = pipe.Expire(ctx, cacheKey, time.Hour).Err()

			if err != nil {
				return err
			}

			return nil
		})

		if err != nil {
			slog.Error("Failed to cache font list", "error", err)
		}
	}

	return mo.Ok(lo.Filter(append(strings.Split(fontListResult.OrEmpty(), "\n"), strings.Split(langFontListResult.OrEmpty(), "\n")...), func(x string, index int) bool {
		return x != ""
	}))
}

func (r *FirestoreSettingsRepository) Save(ctx context.Context, userID string, diagram values.Diagram, s settings.Settings) mo.Result[*settings.Settings] {
	_, err := r.client.Collection(usersCollection).Doc(userID).Collection(settingsCollection).Doc(diagram.String()).Set(ctx, s)

	if err != nil {
		return mo.Err[*settings.Settings](err)
	}

	return mo.Ok(&s)
}
