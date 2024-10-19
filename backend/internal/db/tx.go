package db

import (
	"context"
	"log/slog"

	"cloud.google.com/go/firestore"
	"github.com/harehare/textusm/internal/config"
	"github.com/harehare/textusm/internal/context/values"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Transaction interface {
	Do(ctx context.Context, fn func(ctx context.Context) error) error
}

type postgresTx struct {
	db *pgxpool.Pool
}

type firestoreTx struct {
	db *firestore.Client
}

func NewPostgresTx(config *config.Config) Transaction {
	return &postgresTx{db: config.DBConn}
}

func NewFirestoreTx(config *config.Config) Transaction {
	return &firestoreTx{db: config.FirestoreClient}
}

func (t *postgresTx) Do(ctx context.Context, fn func(ctx context.Context) error) error {
	tx, err := t.db.Begin(ctx)
	if err != nil {
		return err
	}
	ctx = values.WithDBTx(ctx, &tx)

	_, err = tx.Exec(ctx, "SET LOCAL app.uid = '"+values.GetUID(ctx).MustGet()+"';")

	if err != nil {
		return err
	}

	if err = fn(ctx); err != nil {
		if txErr := tx.Rollback(ctx); txErr != nil {
			return err
		}

		slog.Error(err.Error())
		return err
	}

	if err = tx.Commit(ctx); err != nil {
		return err
	}
	return nil
}

func (t *firestoreTx) Do(ctx context.Context, fn func(ctx context.Context) error) error {
	return t.db.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
		ctx = values.WithFirestoreTx(ctx, tx)
		return fn(ctx)
	})
}
