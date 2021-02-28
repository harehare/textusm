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
	"github.com/gorilla/mux"
	"github.com/kelseyhightower/envconfig"
	"github.com/urfave/negroni"

	"github.com/harehare/textusm/api/handler"
	"github.com/harehare/textusm/api/middleware"
	"github.com/harehare/textusm/pkg/repository"
	"github.com/harehare/textusm/pkg/service"
	"github.com/phyber/negroni-gzip/gzip"

	negronilogrus "github.com/meatballhat/negroni-logrus"
	"github.com/rs/cors"
	"github.com/sirupsen/logrus"

	gqlHandler "github.com/99designs/gqlgen/graphql/handler"
	"github.com/99designs/gqlgen/graphql/handler/transport"
	"google.golang.org/api/option"
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

	repo := repository.NewFirestoreRepository(firestore)
	service := service.NewService(repo)
	r := mux.NewRouter()
	c := cors.New(cors.Options{
		AllowedOrigins: []string{"https://app.textusm.com", "http://localhost:3000"},
		AllowedMethods: []string{"POST"},
		AllowedHeaders: []string{"Content-Type", "Authorization"},
	})

	r.HandleFunc("/healthcheck", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		fmt.Fprintf(w, "{\"status\": \"OK\"}")
	})

	root := mux.NewRouter()
	r.PathPrefix("/graphql").Handler(negroni.New(
		negroni.HandlerFunc(middleware.AuthMiddleware(app)),
		negroni.HandlerFunc(middleware.LoggingMiddleware),
		negroni.Wrap(root)))
	subRouter := root.PathPrefix("/").Subrouter()
	g := gqlHandler.New(NewExecutableSchema(Config{Resolvers: &Resolver{service: service}}))
	g.AddTransport(transport.Options{})
	g.AddTransport(transport.POST{})
	subRouter.Methods("POST").Path("/graphql").Handler(g)

	apiBase := mux.NewRouter()
	r.PathPrefix("/api").Handler(negroni.New(
		negroni.Wrap(apiBase)))
	share := apiBase.PathPrefix("/api").Subrouter()
	share.Methods("POST").Path("/urlshorter").HandlerFunc(handler.Shorter)

	n := negroni.New()
	n.Use(negroni.NewRecovery())
	n.Use(negroni.HandlerFunc(middleware.ApiMiddleware))
	n.Use(c)
	n.Use(negronilogrus.NewCustomMiddleware(logrus.InfoLevel, &logrus.JSONFormatter{}, "textusm"))
	n.Use(gzip.Gzip(gzip.BestSpeed))
	n.UseHandler(r)

	done := make(chan bool, 1)
	quit := make(chan os.Signal, 1)

	signal.Notify(quit, os.Interrupt)
	signal.Notify(quit, syscall.SIGTERM)

	s := &http.Server{
		Addr:              fmt.Sprintf(":%s", env.Port),
		Handler:           n,
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
