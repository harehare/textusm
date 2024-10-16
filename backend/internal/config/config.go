package config

import (
	"context"
	"encoding/base64"
	"log/slog"

	"cloud.google.com/go/firestore"
	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/storage"
	"github.com/google/wire"
	"github.com/jackc/pgx/v5/pgxpool"

	"google.golang.org/api/option"
)

type Config struct {
	FirebaseApp     *firebase.App
	FirestoreClient *firestore.Client
	DBConn          *pgxpool.Pool
	StorageClient   *storage.Client
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

	var conn *pgxpool.Pool

	if env.DatabaseURL != "" {
		cfg, err := pgxpool.ParseConfig(env.DatabaseURL)
		if err != nil {
			return nil, err
		}

		conn, err = pgxpool.NewWithConfig(ctx, cfg)

		if err != nil {
			return nil, err
		}
	}

	config := Config{
		FirebaseApp:     app,
		FirestoreClient: firestore,
		StorageClient:   storage,
		DBConn:          conn,
	}

	return &config, nil
}
