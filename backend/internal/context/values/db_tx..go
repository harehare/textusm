package values

import (
	"context"
	"database/sql"

	"github.com/samber/mo"
)

type dbTxKey struct{}

func GetDBTx(ctx context.Context) mo.Option[*sql.Tx] {
	v := ctx.Value(dbTxKey{})
	if v == nil {
		return mo.None[*sql.Tx]()
	}
	return mo.Some(v.(*sql.Tx))
}

func WithDBTx(ctx context.Context, tx *sql.Tx) context.Context {
	return context.WithValue(ctx, dbTxKey{}, tx)
}
