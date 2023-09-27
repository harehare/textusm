package values

import (
	"context"

	"cloud.google.com/go/firestore"
	"github.com/samber/mo"
)

type txKey struct{}

func GetTx(ctx context.Context) mo.Option[*firestore.Transaction] {
	v := ctx.Value(txKey{})
	if v == nil {
		return mo.None[*firestore.Transaction]()
	}
	return mo.Some(v.(*firestore.Transaction))
}

func WithTx(ctx context.Context, tx *firestore.Transaction) context.Context {
	return context.WithValue(ctx, txKey{}, tx)
}
