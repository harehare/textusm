package app

import (
	"encoding/base64"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"golang.org/x/exp/slog"

	"context"

	firebase "firebase.google.com/go/v4"
	"github.com/kelseyhightower/envconfig"
	"github.com/redis/go-redis/v9"

	"github.com/harehare/textusm/internal/domain/service"
	itemRepo "github.com/harehare/textusm/internal/infra/firebase/item"
	settingsRepo "github.com/harehare/textusm/internal/infra/firebase/settings"
	shareRepo "github.com/harehare/textusm/internal/infra/firebase/share"
	userRepo "github.com/harehare/textusm/internal/infra/firebase/user"
	"github.com/harehare/textusm/internal/presentation/api"
	"github.com/harehare/textusm/internal/presentation/api/middleware"
	resolver "github.com/harehare/textusm/internal/presentation/graphql"

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
	Version             string `required:"true" envconfig:"API_VERSION"`
	Port                string `required:"true" envconfig:"PORT"`
	Credentials         string `required:"true" envconfig:"GOOGLE_APPLICATION_CREDENTIALS_JSON"`
	DatabaseCredentials string `required:"true" envconfig:"DATABASE_GOOGLE_APPLICATION_CREDENTIALS_JSON"`
	TlsCertFile         string `envconfig:"TLS_CERT_FILE" default:""`
	TlsKeyFile          string `envconfig:"TLS_KEY_FILE"  default:""`
	GithubClientID      string `envconfig:"GITHUB_CLIENT_ID"  default:""`
	GithubClientSecret  string `envconfig:"GITHUB_CLIENT_SECRET"  default:""`
	StorageBucketName   string `required:"true" envconfig:"STORAGE_BUCKET_NAME"`
	GoEnv               string `required:"true" envconfig:"GO_ENV"`
	RedisUrl            string `required:"false" envconfig:"REDIS_URL"`
}

var (
	env Env
)

func Run() int {
	err := envconfig.Process("", &env)

	if err != nil {
		slog.Error("error initializing app", "error", err)
		return 1
	}

	setupLogger(env.GoEnv)

	cred, err := base64.StdEncoding.DecodeString(env.Credentials)

	if err != nil {
		slog.Error("error initializing app", "error", err)
		return 1
	}

	dbCred, err := base64.StdEncoding.DecodeString(env.DatabaseCredentials)

	if err != nil {
		slog.Error("error initializing app", "error", err)
		return 1
	}

	ctx := context.Background()
	opt := option.WithCredentialsJSON(cred)
	dbOpt := option.WithCredentialsJSON(dbCred)
	app, err := firebase.NewApp(ctx, nil, opt)

	if err != nil {
		slog.Error("error initializing app", "error", err)
		return 1
	}

	firebaseConfig := &firebase.Config{
		StorageBucket: env.StorageBucketName,
	}
	fbApp, err := firebase.NewApp(ctx, firebaseConfig, dbOpt)

	if err != nil {
		slog.Error("error initializing app", "error", err)
		return 1
	}

	firestore, err := fbApp.Firestore(ctx)

	if err != nil {
		slog.Error("error initializing firestore", "error", err)
		return 1
	}

	storage, err := fbApp.Storage(ctx)

	if err != nil {
		slog.Error("error initializing storage", "error", err)
		return 1
	}

	var rdb *redis.Client

	if env.RedisUrl != "" {
		rdb = redis.NewClient(&redis.Options{
			Addr: env.RedisUrl,
		})
	}

	repo := itemRepo.NewFirestoreItemRepository(firestore, storage)
	shareRepo := shareRepo.NewFirestoreShareRepository(firestore, storage)
	userRepo := userRepo.NewFirebaseUserRepository(app)
	gistRepo := itemRepo.NewFirestoreGistItemRepository(firestore)
	settingsRepo := settingsRepo.NewFirestoreSettingsRepository(firestore, storage, rdb)
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
		AllowedMethods:   []string{"GET", "POST", "OPTIONS", "DELETE"},
		AllowedHeaders:   []string{"accept", "authorization", "content-type"},
		AllowCredentials: false,
	})

	r.Get("/version", func(rw http.ResponseWriter, _ *http.Request) {
		_, err := rw.Write([]byte(env.Version))
		if err != nil {
			rw.WriteHeader(http.StatusInternalServerError)
		}
	})

	restApi := api.New(*gistService, *settingsService)

	r.Route("/api/v1", func(r chi.Router) {
		r.Use(chiMiddleware.AllowContentType("application/json"))
		r.Use(middleware.IPMiddleware())
		r.Use(cors)

		r.Route("/settings", func(r chi.Router) {
			r.Use(httprate.LimitByIP(10, 1*time.Minute))
			r.Get("/usable-font-list", restApi.UsableFontList)
		})

		r.Route("/", func(r chi.Router) {
			r.Use(middleware.AuthMiddleware(app))
			r.Use(httprate.LimitByIP(10, 1*time.Minute))
			r.Route("/token", func(r chi.Router) {
				r.Delete("/gist/revoke", restApi.RevokeGistToken)
			})
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

	logger := slog.New(opts.NewJSONHandler(os.Stdout))
	slog.SetDefault(logger)
}
