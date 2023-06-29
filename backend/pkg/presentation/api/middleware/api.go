package middleware

import (
	"net/http"
)

func ApiMiddleware(w http.ResponseWriter, r *http.Request, next http.HandlerFunc) {
	w.Header().Set("content-type", "application/json")
	next(w, r)
}
