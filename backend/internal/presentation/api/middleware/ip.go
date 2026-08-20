package middleware

import (
	"net/http"

	chiMiddleware "github.com/go-chi/chi/v5/middleware"
	"github.com/harehare/textusm/internal/context/values"
)

func IPMiddleware() func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			next.ServeHTTP(w, r.WithContext(values.WithIP(r.Context(), chiMiddleware.GetClientIP(r.Context()))))
		})
	}
}
