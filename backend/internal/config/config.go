package config

import (
	"context"
	"encoding/base64"
	"log/slog"

	"cloud.google.com/go/firestore"
	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/storage"
	"github.com/google/wire"
	"github.com/redis/go-redis/v9"
	"google.golang.org/api/option"
)

type Config struct {
	FirebaseApp     *firebase.App
	FirestoreClient *firestore.Client
	StorageClient   *storage.Client
	RedisClient     *redis.Client
}

var Set = wire.NewSet(
	NewEnv,
	NewLogger,
	NewConfig,
)

func NewConfig(env *Env) (*Config, error) {
	cred, err := base64.StdEncoding.DecodeString(env.Credentials)

	if err != nil {
		slog.Error("error initializing app", "error", err)
		return nil, err
	}

	dbCred, err := base64.StdEncoding.DecodeString(env.DatabaseCredentials)

	if err != nil {
		slog.Error("error initializing app", "error", err)
		return nil, err
	}

	ctx := context.Background()
	opt := option.WithCredentialsJSON(cred)
	dbOpt := option.WithCredentialsJSON(dbCred)
	app, err := firebase.NewApp(ctx, nil, opt)

	if err != nil {
		slog.Error("error initializing app", "error", err)
		return nil, err
	}

	firebaseConfig := &firebase.Config{
		StorageBucket: env.StorageBucketName,
	}
	fbApp, err := firebase.NewApp(ctx, firebaseConfig, dbOpt)

	if err != nil {
		slog.Error("error initializing app", "error", err)
		return nil, err
	}

	firestore, err := fbApp.Firestore(ctx)

	if err != nil {
		slog.Error("error initializing firestore", "error", err)
		return nil, err
	}

	storage, err := fbApp.Storage(ctx)

	if err != nil {
		slog.Error("error initializing storage", "error", err)
		return nil, err
	}

	var rdb *redis.Client

	if env.RedisUrl != "" {
		opts, err := redis.ParseURL(env.RedisUrl)

		if err != nil {
			slog.Error("error initializing redis", "error", err)
			return nil, err
		}
		rdb = redis.NewClient(opts)
	}

	config := Config{
		FirebaseApp:     app,
		FirestoreClient: firestore,
		StorageClient:   storage,
		RedisClient:     rdb,
	}

	return &config, nil
}
