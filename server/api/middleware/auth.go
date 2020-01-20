package middleware

import (
	"net/http"
	"strings"

	"context"

	firebase "firebase.google.com/go"
	"github.com/urfave/negroni"
)

type key int

var (
	UIDKey key
)

func AuthMiddleware(app *firebase.App) negroni.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request, next http.HandlerFunc) {
		idToken := strings.SplitN(r.Header.Get("Authorization"), " ", 2)

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
		ctx := context.WithValue(r.Context(), UIDKey, token.UID)
		next(w, r.WithContext(ctx))
	}
}
