package values

import (
	"context"

	"github.com/samber/mo"
)

type ipKey struct{}

func GetIP(ctx context.Context) mo.Option[string] {
	v := ctx.Value(ipKey{})
	if v == nil {
		return mo.None[string]()
	}
	return mo.Some(v.(string))
}

func WithIP(ctx context.Context, ip string) context.Context {
	return context.WithValue(ctx, ipKey{}, ip)
}
