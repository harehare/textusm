package values

import (
	"context"

	"github.com/jackc/pgx/v5"
	"github.com/samber/mo"
)

type dbTxKey struct{}

func GetDBTx(ctx context.Context) mo.Option[*pgx.Tx] {
	v := ctx.Value(dbTxKey{})
	if v == nil {
		return mo.None[*pgx.Tx]()
	}
	return mo.Some(v.(*pgx.Tx))
}

func WithDBTx(ctx context.Context, tx *pgx.Tx) context.Context {
	return context.WithValue(ctx, dbTxKey{}, tx)
}
