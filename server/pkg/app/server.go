package app

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

	"github.com/harehare/textusm/pkg/domain/service"
	itemRepo "github.com/harehare/textusm/pkg/infra/firestore/item"
	settingsRepo "github.com/harehare/textusm/pkg/infra/firestore/settings"
	shareRepo "github.com/harehare/textusm/pkg/infra/firestore/share"
	userRepo "github.com/harehare/textusm/pkg/infra/firestore/user"
	"github.com/harehare/textusm/pkg/presentation/api"
	"github.com/harehare/textusm/pkg/presentation/api/middleware"
	resolver "github.com/harehare/textusm/pkg/presentation/graphql"

	gqlHandler "github.com/99designs/gqlgen/graphql/handler"
	"github.com/99designs/gqlgen/graphql/handler/extension"
	"github.com/99designs/gqlgen/graphql/handler/lru"
	"github.com/99designs/gqlgen/graphql/handler/transport"
	"google.golang.org/api/option"

	"github.com/go-chi/chi/v5"
	chiMiddleware "github.com/go-chi/chi/v5/middleware"
	"github.com/go-chi/cors"
	"github.com/go-chi/httprate"
)

type Env struct {
	Host                string `envconfig:"API_HOST"`
	Version             string `envconfig:"API_VERSION"`
	Port                string `envconfig:"PORT"`
	Credentials         string `envconfig:"GOOGLE_APPLICATION_CREDENTIALS_JSON"`
	DatabaseCredentials string `envconfig:"DATABASE_GOOGLE_APPLICATION_CREDENTIALS_JSON"`
	TlsCertFile         string `envconfig:"TLS_CERT_FILE" default:""`
	TlsKeyFile          string `envconfig:"TLS_KEY_FILE"  default:""`
	GithubClientID      string `envconfig:"GITHUB_CLIENT_ID"  default:""`
	GithubClientSecret  string `envconfig:"GITHUB_CLIENT_SECRET"  default:""`
	EmbedWebResource    string `envconfig:"EMBED_WEB_RESOURCE"  default:"0"`
}

var (
	env Env
)

func Run() int {
	err := envconfig.Process("TextUSM", &env)

	if err != nil {
		return 1
	}

	cred, err := base64.StdEncoding.DecodeString(env.Credentials)

	if err != nil {
		return 1
	}

	dbCred, err := base64.StdEncoding.DecodeString(env.DatabaseCredentials)

	if err != nil {
		return 1
	}

	ctx := context.Background()
	opt := option.WithCredentialsJSON(cred)
	dbOpt := option.WithCredentialsJSON(dbCred)
	app, err := firebase.NewApp(ctx, nil, opt)

	if err != nil {
		log.Error().Msg(fmt.Sprintf("error initializing app: %v\n", err))
		return 1
	}

	fbApp, err := firebase.NewApp(ctx, nil, dbOpt)

	if err != nil {
		log.Error().Msg(fmt.Sprintf("error initializing db app: %v\n", err))
		return 1
	}

	firestore, err := fbApp.Firestore(ctx)

	if err != nil {
		log.Error().Msg(fmt.Sprintf("error initializing firestore: %v\n", err))
		return 1
	}

	repo := itemRepo.NewFirestoreItemRepository(firestore)
	shareRepo := shareRepo.NewFirestoreShareRepository(firestore)
	userRepo := userRepo.NewFirebaseUserRepository(app)
	gistRepo := itemRepo.NewFirestoreGistItemRepository(firestore)
	settingsRepo := settingsRepo.NewFirestoreSettingsRepository(firestore)
	itemService := service.NewService(repo, shareRepo, userRepo)
	gistService := service.NewGistService(gistRepo, env.GithubClientID, env.GithubClientSecret)
	settingsService := service.NewSettingsService(settingsRepo, env.GithubClientID, env.GithubClientSecret)

	r := chi.NewRouter()
	r.Use(chiMiddleware.Compress(5))
	r.Use(chiMiddleware.RequestID)
	r.Use(chiMiddleware.RealIP)
	r.Use(chiMiddleware.Logger)
	r.Use(chiMiddleware.Recoverer)
	r.Use(chiMiddleware.Heartbeat("/healthcheck"))

	cors := cors.Handler(cors.Options{
		AllowedOrigins:   []string{"https://app.textusm.com", "http://localhost:3000", "https://localhost:3000"},
		AllowedMethods:   []string{"POST", "OPTIONS", "DELETE"},
		AllowedHeaders:   []string{"accept", "authorization", "content-type"},
		AllowCredentials: false,
	})

	r.Get("/version", func(rw http.ResponseWriter, r *http.Request) {
		_, err := rw.Write([]byte(env.Version))
		if err != nil {
			rw.WriteHeader(http.StatusInternalServerError)
		}
	})

	r.Route("/api/v1", func(r chi.Router) {
		r.Use(chiMiddleware.AllowContentType("application/json"))
		r.Use(middleware.AuthMiddleware(app))
		r.Use(middleware.IPMiddleware())
		r.Use(httprate.LimitByIP(10, 1*time.Minute))
		r.Use(cors)

		restApi := api.New(*gistService)

		r.Route("/token", func(r chi.Router) {
			r.Delete("/gist/revoke", restApi.RevokeGistToken)
		})
	})

	r.Route("/graphql", func(r chi.Router) {
		r.Use(chiMiddleware.AllowContentType("application/json"))
		r.Use(middleware.AuthMiddleware(app))
		r.Use(middleware.IPMiddleware())
		r.Use(cors)
		r.Use(httprate.LimitByIP(100, 1*time.Minute))
		graphql := gqlHandler.New(resolver.NewExecutableSchema(resolver.Config{Resolvers: resolver.New(itemService, gistService, settingsService, firestore)}))
		graphql.AddTransport(transport.Options{})
		graphql.AddTransport(transport.POST{})
		graphql.SetQueryCache(lru.New(100))
		if os.Getenv("GO_ENV") != "production" {
			graphql.Use(extension.Introspection{})
		}
		r.Handle("/", graphql)
	})

	if env.EmbedWebResource == "1" {
		r.Get("/*", EmbedFileServeHandler())
	}

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

func gracefullShutdown(ctx context.Context, server *http.Server, quit <-chan os.Signal, done chan<- bool) {
	<-quit
	log.Info().Msg("Server is shutting down")

	server.SetKeepAlivesEnabled(false)
	if err := server.Shutdown(ctx); err != nil {
		log.Error().Msg(fmt.Sprintf("Could not gracefully shutdown the server: %v\n", err))
	}
	close(done)
}
