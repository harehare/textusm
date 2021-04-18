package values

import "context"

type ipKey struct{}

func GetIP(ctx context.Context) *string {
	v := ctx.Value(ipKey{})
	if v == nil {
		return nil
	}
	r := v.(string)
	return &r
}

func WithIP(ctx context.Context, ip string) context.Context {
	return context.WithValue(ctx, ipKey{}, ip)
}
