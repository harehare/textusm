package values

import (
	"context"
	"cloud.google.com/go/firestore"
)

type txKey struct{}

func GetTx(ctx context.Context) *firestore.Transaction {
	v := ctx.Value(txKey{})
	if v == nil {
		return nil
	}
	return v.(*firestore.Transaction)
}

func WithTx(ctx context.Context, tx *firestore.Transaction) context.Context {
	return context.WithValue(ctx, txKey{}, tx)
}
