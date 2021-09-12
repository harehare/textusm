//go:build !embed

package app

import (
	"net/http"
)

func EmbedFileServeHandler() func(w http.ResponseWriter, r *http.Request) {
	return func(w http.ResponseWriter, r *http.Request) {}
}
