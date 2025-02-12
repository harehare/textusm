package config

import (
	"context"
	"database/sql"
	"encoding/base64"
	"log/slog"

	"cloud.google.com/go/firestore"
	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/storage"
	"github.com/google/wire"
	"github.com/jackc/pgx/v5/pgxpool"

	_ "github.com/mattn/go-sqlite3"
	"google.golang.org/api/option"
)

type Config struct {
	FirebaseApp     *firebase.App
	FirestoreClient *firestore.Client
	PostgresConn    *pgxpool.Pool
	SqlConn         *sql.Conn
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

	var (
		pgConn  *pgxpool.Pool
		sqlConn *sql.Conn
	)

	if env.DatabaseURL != "" {
		if env.DBType == "sqlite" {
			db, err := sql.Open("sqlite3", env.DatabaseURL)

			if err != nil {
				return nil, err
			}

			conn, err := db.Conn(ctx)

			if err != nil {
				return nil, err
			}
			sqlConn = conn
		} else {
			cfg, err := pgxpool.ParseConfig(env.DatabaseURL)
			if err != nil {
				return nil, err
			}

			pgConn, err = pgxpool.NewWithConfig(ctx, cfg)

			if err != nil {
				return nil, err
			}
		}
	}

	config := Config{
		FirebaseApp:     app,
		FirestoreClient: firestore,
		StorageClient:   storage,
		PostgresConn:    pgConn,
		SqlConn:         sqlConn,
	}

	return &config, nil
}
