package middleware

import (
	"net/http"
	"strings"

	firebase "firebase.google.com/go"
	"github.com/harehare/textusm/pkg/context/values"
)

func AuthMiddleware(app *firebase.App) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			authHeader := r.Header.Get("Authorization")
			if authHeader == "" {
				next.ServeHTTP(w, r)
				return
			}

			idToken := strings.SplitN(authHeader, " ", 2)

			if len(idToken) < 2 && idToken[0] != "Bearer" {
				http.Error(w, "{\"error\": \"authorization failed\"}", http.StatusUnauthorized)
				return
			}

			client, err := app.Auth(r.Context())
			if err != nil {
				http.Error(w, "{\"error\": \"authorization failed\"}", http.StatusUnauthorized)
				return
			}

			token, err := client.VerifyIDToken(r.Context(), idToken[1])
			if err != nil {
				http.Error(w, "{\"error\": \"authorization failed\"}", http.StatusForbidden)
				return
			}

			next.ServeHTTP(w, r.WithContext(values.WithUID(r.Context(), token.UID)))
		})
	}
}
