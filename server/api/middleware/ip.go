package middleware

import (
	"net/http"

	"github.com/harehare/textusm/pkg/values"
)

func IPMiddleware() func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			next.ServeHTTP(w, r.WithContext(values.WithIP(r.Context(), r.RemoteAddr)))
		})
	}
}
