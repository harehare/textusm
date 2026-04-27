package main

import (
	"log/slog"
	"net/http"
	"os"

	backend "github.com/harehare/textusm/internal/app"
)

func main() {
	if err := run(); err != nil {
		slog.Error("server error", "error", err)
		os.Exit(1)
	}
}

func run() error {
	server, cleanup, err := backend.Server()

	if err != nil {
		return err
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
		return err
	}

	return nil
}
