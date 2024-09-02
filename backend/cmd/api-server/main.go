package main

import (
	"log/slog"
	"os"

	backend "github.com/harehare/textusm/internal/app"
)

func main() {
	tlsCertFile := os.Getenv("TLS_CERT_FILE")
	tlsKeyFile := os.Getenv("TLS_KEY_FILE")

	server, err := backend.Server()

	if err != nil {
		os.Exit(1)
	}

	if tlsCertFile != "" && tlsKeyFile != "" {
		err = server.ListenAndServeTLS(tlsCertFile, tlsKeyFile)
	} else {
		err = server.ListenAndServe()
	}

	if err != nil {
		slog.Error(err.Error())
		os.Exit(1)
	} else {
		os.Exit(0)
	}
}
