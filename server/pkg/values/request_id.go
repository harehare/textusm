package values

import "context"

type requestIDKey struct{}

func GetRequestID(ctx context.Context) string {
	requestID := ctx.Value(requestIDKey{})

	if requestID == nil {
		return ""
	}

	return requestID.(string)
}

func WithRequestID(ctx context.Context, requestID string) context.Context {
	return context.WithValue(ctx, requestIDKey{}, requestID)
}
