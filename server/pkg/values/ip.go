package values

import "context"

type ipKey struct{}

func GetIP(ctx context.Context) string {
	return ctx.Value(ipKey{}).(string)
}

func WithIP(ctx context.Context, ip string) context.Context {
	return context.WithValue(ctx, ipKey{}, ip)
}
