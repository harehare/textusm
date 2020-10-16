package middleware

type contextKey int

var (
	UIDKey       contextKey = 1
	RequestIDKey contextKey = 2
)
