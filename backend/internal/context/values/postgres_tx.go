package values

import (
	"context"

	"github.com/jackc/pgx/v5"
	"github.com/samber/mo"
)

type postgresTxKey struct{}

func GetPostgresTx(ctx context.Context) mo.Option[*pgx.Tx] {
	v := ctx.Value(postgresTxKey{})
	if v == nil {
		return mo.None[*pgx.Tx]()
	}
	return mo.Some(v.(*pgx.Tx))
}

func WithPostgresTx(ctx context.Context, tx *pgx.Tx) context.Context {
	return context.WithValue(ctx, postgresTxKey{}, tx)
}
