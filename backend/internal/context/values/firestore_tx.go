package values

import (
	"context"

	"cloud.google.com/go/firestore"
	"github.com/samber/mo"
)

type firestoreTxKey struct{}

func GetFirestoreTx(ctx context.Context) mo.Option[*firestore.Transaction] {
	v := ctx.Value(firestoreTxKey{})
	if v == nil {
		return mo.None[*firestore.Transaction]()
	}
	return mo.Some(v.(*firestore.Transaction))
}

func WithFirestoreTx(ctx context.Context, tx *firestore.Transaction) context.Context {
	return context.WithValue(ctx, firestoreTxKey{}, tx)
}
