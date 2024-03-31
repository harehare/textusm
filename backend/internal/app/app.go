package app

import (
	"log/slog"

	"github.com/harehare/textusm/internal/config"
)

func Run() int {
	env, err := config.NewEnv()

	if err != nil {
		slog.Error("error initializing app", "error", err)
		return 1
	}

	server, err := InitializeServer()

	if err != nil {
		slog.Error("error initializing app", "error", err)
		return 1
	}

	slog.Info("Start server", "port", env.Port)

	if env.TlsCertFile != "" && env.TlsKeyFile != "" {
		err = server.ListenAndServeTLS(env.TlsCertFile, env.TlsKeyFile)
	} else {
		err = server.ListenAndServe()
	}

	if err != nil {
		return 1
	}

	return 0
}
