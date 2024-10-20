package app

import (
	"log/slog"
	"net/http"
	"os"
	"strings"

	"github.com/harehare/textusm/internal/config"
)

func Server() (server *http.Server, cleanup func(), err error) {
	env, err := config.NewEnv()

	if err != nil {
		slog.Error("error initializing app", "error", err)
		return
	}

	DBType := os.Getenv("DB_TYPE")

	if strings.ToLower(DBType) == "postgres" {
		server, cleanup, err = InitializePostgresServer()
	} else {
		server, cleanup, err = InitializeFirebaseServer()
	}

	if err != nil {
		slog.Error("error initializing app", "error", err)
		return
	}

	slog.Info("Start server", "port", env.Port)

	return
}
