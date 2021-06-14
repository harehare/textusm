package values

import "context"

type uidKey struct{}

func GetUID(ctx context.Context) *string {
	v := ctx.Value(uidKey{})
	if v == nil {
		return nil
	}
	r := v.(string)
	return &r
}

func WithUID(ctx context.Context, uid string) context.Context {
	return context.WithValue(ctx, uidKey{}, uid)
}
