package server

import (
	"encoding/base64"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"context"

	firebase "firebase.google.com/go"
	"github.com/gorilla/mux"
	"github.com/kelseyhightower/envconfig"
	"github.com/urfave/negroni"

	"github.com/harehare/textusm/api/handler"
	"github.com/harehare/textusm/api/middleware"
	"github.com/harehare/textusm/pkg/item"
	"github.com/phyber/negroni-gzip/gzip"

	negronilogrus "github.com/meatballhat/negroni-logrus"
	"github.com/rs/cors"
	"github.com/sirupsen/logrus"

	gqlHandler "github.com/99designs/gqlgen/handler"
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

	opt := option.WithCredentialsJSON(b)
	app, err = firebase.NewApp(context.Background(), nil, opt)

	if err != nil {
		log.Fatalf("error initializing app: %v\n", err)
		return 1
	}

	firestore, err := app.Firestore(context.Background())

	if err != nil {
		log.Fatalf("error initializing firestore: %v\n", err)
		return 1
	}

	repo := item.NewFirestoreRepository(firestore)
	service := item.NewService(repo)
	r := mux.NewRouter()
	c := cors.New(cors.Options{
		AllowedOrigins: []string{"*"},
		AllowedMethods: []string{"GET", "POST", "DELETE"},
		AllowedHeaders: []string{"Content-Type", "Authorization"},
	})

	r.HandleFunc("/healthcheck", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		fmt.Fprintf(w, "{\"status\": \"OK\"}")
	})

	root := mux.NewRouter()
	r.PathPrefix("/graphql").Handler(negroni.New(
		negroni.HandlerFunc(middleware.AuthMiddleware(app)),
		negroni.Wrap(root)))
	subRouter := root.PathPrefix("/").Subrouter()
	subRouter.Methods("POST").Path("/graphql").HandlerFunc(gqlHandler.GraphQL(NewExecutableSchema(Config{Resolvers: &Resolver{service: service}})))

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
	n.Use(gzip.Gzip(gzip.DefaultCompression))
	n.UseHandler(r)

	done := make(chan bool, 1)
	quit := make(chan os.Signal, 1)

	signal.Notify(quit, os.Interrupt)
	signal.Notify(quit, syscall.SIGTERM)

	s := &http.Server{
		Addr:              fmt.Sprintf(":%s", env.Port),
		Handler:           n,
		ReadTimeout:       8 * time.Second,
		WriteTimeout:      8 * time.Second,
		MaxHeaderBytes:    1 << 20,
		ReadHeaderTimeout: 8 * time.Second,
	}

	go gracefullShutdown(s, quit, done)
	err = s.ListenAndServe()

	if err != nil {
		return 1
	}

	return 0
}

func gracefullShutdown(server *http.Server, quit <-chan os.Signal, done chan<- bool) {
	<-quit
	log.Println("Server is shutting down...")

	server.SetKeepAlivesEnabled(false)
	if err := server.Shutdown(context.Background()); err != nil {
		log.Fatalf("Could not gracefully shutdown the server: %v\n", err)
	}
	close(done)
}
