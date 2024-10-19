package app

import (
	"log/slog"
	"net/http"

	"github.com/harehare/textusm/internal/config"
)

func Server() (server *http.Server, cleanup func(), err error) {
	env, err := config.NewEnv()

	if err != nil {
		slog.Error("error initializing app", "error", err)
		return
	}

	server, cleanup, err = InitializePostgresServer()

	if err != nil {
		slog.Error("error initializing app", "error", err)
		return
	}

	slog.Info("Start server", "port", env.Port)

	return
}
