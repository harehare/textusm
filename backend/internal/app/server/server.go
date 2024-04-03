package server

import (
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"log/slog"

	"context"

	"github.com/go-chi/chi/v5"
	"github.com/harehare/textusm/internal/config"
)

func NewServer(handler *chi.Mux, env *config.Env) *http.Server {
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

	return s
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
