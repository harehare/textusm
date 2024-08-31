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
	var (
		app          *firebase.App
		fbApp        *firebase.App
		cred, dbCred []byte
	)

	if env.Credentials != "" {
		_cred, err := base64.StdEncoding.DecodeString(env.Credentials)

		if err != nil {
			slog.Error("error initializing app", "error", err)
			return nil, err
		}
		cred = _cred
	}

	if env.DatabaseCredentials != "" {
		_dbCred, err := base64.StdEncoding.DecodeString(env.DatabaseCredentials)

		if err != nil {
			slog.Error("error initializing app", "error", err)
			return nil, err
		}

		dbCred = _dbCred
	}

	ctx := context.Background()

	if cred != nil && dbCred != nil {
		firebaseConfig := &firebase.Config{
			StorageBucket: env.StorageBucketName,
		}
		opt := option.WithCredentialsJSON(cred)
		dbOpt := option.WithCredentialsJSON(dbCred)
		_app, err := firebase.NewApp(ctx, nil, opt)

		if err != nil {
			slog.Error("error initializing app", "error", err)
			return nil, err
		}

		_fbApp, err := firebase.NewApp(ctx, firebaseConfig, dbOpt)

		if err != nil {
			slog.Error("error initializing app", "error", err)
			return nil, err
		}

		app = _app
		fbApp = _fbApp
	} else {
		firebaseConfig := &firebase.Config{
			ProjectID:     "textusm",
			StorageBucket: env.StorageBucketName,
		}
		_app, err := firebase.NewApp(ctx, firebaseConfig)

		if err != nil {
			slog.Error("error initializing app", "error", err)
			return nil, err
		}

		_fbApp, err := firebase.NewApp(ctx, firebaseConfig)

		if err != nil {
			slog.Error("error initializing app", "error", err)
			return nil, err
		}

		app = _app
		fbApp = _fbApp
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
