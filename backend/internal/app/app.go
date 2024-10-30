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

	switch strings.ToLower(DBType) {
	case "postgres":
		server, cleanup, err = InitializePostgresServer()
	case "sqlite":
		server, cleanup, err = InitializeSqliteServer()
	default:
		server, cleanup, err = InitializeFirebaseServer()
	}

	if err != nil {
		slog.Error("error initializing app", "error", err)
		return
	}

	slog.Info("Start server", "port", env.Port)

	return
}
