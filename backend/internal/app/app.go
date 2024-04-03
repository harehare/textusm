package app

import (
	"log/slog"
	"net/http"

	"github.com/harehare/textusm/internal/config"
)

func Server() (*http.Server, error) {
	env, err := config.NewEnv()

	if err != nil {
		slog.Error("error initializing app", "error", err)
		return nil, err
	}

	server, err := InitializeServer()

	if err != nil {
		slog.Error("error initializing app", "error", err)
		return nil, err
	}

	slog.Info("Start server", "port", env.Port)

	return server, nil
}
