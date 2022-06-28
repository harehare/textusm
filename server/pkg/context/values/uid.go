package values

import (
	"context"

	"github.com/samber/mo"
)

type uidKey struct{}

func GetUID(ctx context.Context) mo.Option[string] {
	v := ctx.Value(uidKey{})
	if v == nil {
		return mo.None[string]()
	}
	return mo.Some(v.(string))
}

func WithUID(ctx context.Context, uid string) context.Context {
	return context.WithValue(ctx, uidKey{}, uid)
}
