package values

import "context"

type uidKey struct{}

func GetUID(ctx context.Context) string {
	return ctx.Value(uidKey{}).(string)
}

func WithUID(ctx context.Context, uid string) context.Context {
	return context.WithValue(ctx, uidKey{}, uid)
}
