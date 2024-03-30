package app

import (
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"log/slog"

	"context"

	"github.com/harehare/textusm/internal/config"
)

func Run() int {
	env, err := config.NewEnv()

	if err != nil {
		slog.Error("error initializing app", "error", err)
		return 1
	}

	setupLogger(env.GoEnv)

	handler, err := InitializeHandler()

	if err != nil {
		slog.Error("error initializing app", "error", err)
		return 1
	}

	done := make(chan bool, 1)
	quit := make(chan os.Signal, 1)

	signal.Notify(quit, os.Interrupt)
	signal.Notify(quit, syscall.SIGTERM)

	s := &http.Server{
		Addr:              fmt.Sprintf(":%s", env.Port),
		Handler:           handler,
		ReadTimeout:       16 * time.Second,
		WriteTimeout:      16 * time.Second,
		MaxHeaderBytes:    1 << 20,
		ReadHeaderTimeout: 8 * time.Second,
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	go gracefulShutdown(ctx, s, quit, done)

	slog.Info("Start server", "port", env.Port)

	if env.TlsCertFile != "" && env.TlsKeyFile != "" {
		err = s.ListenAndServeTLS(env.TlsCertFile, env.TlsKeyFile)
	} else {
		err = s.ListenAndServe()
	}

	if err != nil {
		return 1
	}

	return 0
}

func gracefulShutdown(ctx context.Context, server *http.Server, quit <-chan os.Signal, done chan<- bool) {
	<-quit
	slog.Info("Server is shutting down")

	server.SetKeepAlivesEnabled(false)
	if err := server.Shutdown(ctx); err != nil {
		slog.Error("Could not gracefully shutdown the server", "error", err)
	}
	close(done)
}

func setupLogger(goEnv string) {
	var opts slog.HandlerOptions

	if goEnv == "development" {
		opts = slog.HandlerOptions{
			Level: slog.LevelDebug,
		}
	} else {
		opts = slog.HandlerOptions{
			Level: slog.LevelWarn,
		}
	}

	logger := slog.New(slog.NewJSONHandler(os.Stdout, &opts))
	slog.SetDefault(logger)
}
