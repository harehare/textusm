package server

import (
	"encoding/base64"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/rs/zerolog/log"

	"context"

	firebase "firebase.google.com/go"
	"github.com/kelseyhightower/envconfig"

	"github.com/harehare/textusm/api/handler"
	"github.com/harehare/textusm/api/middleware"
	"github.com/harehare/textusm/pkg/repository"
	"github.com/harehare/textusm/pkg/service"

	gqlHandler "github.com/99designs/gqlgen/graphql/handler"
	"github.com/99designs/gqlgen/graphql/handler/extension"
	"github.com/99designs/gqlgen/graphql/handler/transport"
	"google.golang.org/api/option"

	"github.com/go-chi/chi/v5"
	chiMiddleware "github.com/go-chi/chi/v5/middleware"
	"github.com/go-chi/cors"
	"github.com/go-chi/httprate"
)

type Env struct {
	Host        string `envconfig:"API_HOST"`
	Port        string `envconfig:"PORT"`
	Credentials string `envconfig:"GOOGLE_APPLICATION_CREDENTIALS_JSON"`
}

var (
	env Env
	app *firebase.App
)

func Run() int {
	envconfig.Process("TextUSM", &env)

	var err error

	b, err := base64.StdEncoding.DecodeString(env.Credentials)

	if err != nil {
		return 1
	}

	ctx := context.Background()
	opt := option.WithCredentialsJSON(b)
	app, err = firebase.NewApp(ctx, nil, opt)

	if err != nil {
		log.Error().Msg(fmt.Sprintf("error initializing app: %v\n", err))
		return 1
	}

	firestore, err := app.Firestore(ctx)

	if err != nil {
		log.Error().Msg(fmt.Sprintf("error initializing firestore: %v\n", err))
		return 1
	}

	repo := repository.NewFirestoreItemRepository(firestore)
	shareRepo := repository.NewFirestoreShareRepository(firestore)
	service := service.NewService(repo, shareRepo)

	r := chi.NewRouter()
	r.Use(chiMiddleware.Compress(5))
	r.Use(chiMiddleware.RequestID)
	r.Use(chiMiddleware.RealIP)
	r.Use(chiMiddleware.Logger)
	r.Use(chiMiddleware.Recoverer)
	r.Use(chiMiddleware.Heartbeat("/healthcheck"))
	r.Route("/graphql", func(r chi.Router) {
		r.Use(chiMiddleware.AllowContentType("application/json"))
		r.Use(middleware.AuthMiddleware(app))
		r.Use(cors.Handler(cors.Options{
			AllowedOrigins:   []string{"https://app.textusm.com", "http://localhost:3000"},
			AllowedMethods:   []string{"POST", "OPTIONS"},
			AllowedHeaders:   []string{"accept", "authorization", "content-type"},
			AllowCredentials: false,
		}))
		r.Use(httprate.LimitByIP(100, 1*time.Minute))
		graphql := gqlHandler.New(NewExecutableSchema(Config{Resolvers: &Resolver{service: service}}))
		graphql.AddTransport(transport.Options{})
		graphql.AddTransport(transport.POST{})
		if os.Getenv("GO_ENV") != "production" {
			graphql.Use(extension.Introspection{})
		}
		r.Handle("/", graphql)
	})
	r.Route("/api", func(r chi.Router) {
		r.Post("/urlshorter", handler.Shorter)
	})

	done := make(chan bool, 1)
	quit := make(chan os.Signal, 1)

	signal.Notify(quit, os.Interrupt)
	signal.Notify(quit, syscall.SIGTERM)

	s := &http.Server{
		Addr:              fmt.Sprintf(":%s", env.Port),
		Handler:           r,
		ReadTimeout:       16 * time.Second,
		WriteTimeout:      16 * time.Second,
		MaxHeaderBytes:    1 << 20,
		ReadHeaderTimeout: 8 * time.Second,
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	go gracefullShutdown(ctx, s, quit, done)

	log.Info().Msg(fmt.Sprintf("Start server %s", env.Port))
	err = s.ListenAndServe()

	if err != nil {
		return 1
	}

	return 0
}

func gracefullShutdown(ctx context.Context, server *http.Server, quit <-chan os.Signal, done chan<- bool) {
	<-quit
	log.Info().Msg("Server is shutting down")

	server.SetKeepAlivesEnabled(false)
	if err := server.Shutdown(ctx); err != nil {
		log.Error().Msg(fmt.Sprintf("Could not gracefully shutdown the server: %v\n", err))
	}
	close(done)
}
