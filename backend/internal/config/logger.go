package config

import (
	"log/slog"
	"os"
)

func NewLogger(env *Env) *slog.Logger {
	var opts slog.HandlerOptions

	if env.GoEnv == "development" {
		opts = slog.HandlerOptions{
			Level: slog.LevelDebug,
		}
	} else {
		opts = slog.HandlerOptions{
			Level: slog.LevelWarn,
		}
	}

	logger := slog.New(slog.NewJSONHandler(os.Stdout, &opts))

	return logger
}
