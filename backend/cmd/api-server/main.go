package main

import (
	"log/slog"
	"net/http"
	"os"

	backend "github.com/harehare/textusm/internal/app"
)

func main() {
	server, cleanup, err := backend.Server()

	if err != nil {
		os.Exit(1)
	}

	defer cleanup()

	tlsCertFile := os.Getenv("TLS_CERT_FILE")
	tlsKeyFile := os.Getenv("TLS_KEY_FILE")

	if tlsCertFile != "" && tlsKeyFile != "" {
		err = server.ListenAndServeTLS(tlsCertFile, tlsKeyFile)
	} else {
		err = server.ListenAndServe()
	}

	if err != nil && err != http.ErrServerClosed {
		slog.Error(err.Error())
		os.Exit(1)
	} else {
		os.Exit(0)
	}
}
