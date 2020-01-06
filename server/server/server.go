package server

import (
	"encoding/base64"
	"fmt"
	"log"
	"net/http"
	"time"

	"context"

	firebase "firebase.google.com/go"
	"github.com/gorilla/mux"
	"github.com/kelseyhightower/envconfig"
	"github.com/urfave/negroni"

	"github.com/harehare/textusm/server/controllers"
	"github.com/harehare/textusm/server/middleware"
	"github.com/phyber/negroni-gzip/gzip"

	negronilogrus "github.com/meatballhat/negroni-logrus"
	"github.com/rs/cors"
	"github.com/sirupsen/logrus"

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

	err = InitDB()

	if err != nil {
		log.Fatalf("error initializing db: %v\n", err)
		return 1
	}

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

	diagramBase := mux.NewRouter()
	r.PathPrefix("/diagram").Handler(negroni.New(
		negroni.HandlerFunc(middleware.AuthMiddleware(app)),
		negroni.Wrap(diagramBase)))
	diagram := diagramBase.PathPrefix("/diagram").Subrouter()
	diagram.Methods("GET").Path("/items").HandlerFunc(controllers.Items)
	diagram.Methods("GET").Path("/items/public").HandlerFunc(controllers.PublicItems)
	diagram.Methods("GET").Path("/items/{ID}").HandlerFunc(controllers.Item(app))
	diagram.Methods("DELETE").Path("/items/{ID}").HandlerFunc(controllers.Remove)
	diagram.Methods("POST").Path("/save").HandlerFunc(controllers.Save)
	diagram.Methods("GET").Path("/search").HandlerFunc(controllers.Search)
	diagram.Methods("POST").Path("/add/user").HandlerFunc(controllers.AddUserToDiagram(app))
	diagram.Methods("POST").Path("/update/role/{ID}").HandlerFunc(controllers.UpdateRole)
	diagram.Methods("DELETE").Path("/delete/user/{ID}/{DiagramID}").HandlerFunc(controllers.DeleteUser)

	apiBase := mux.NewRouter()
	r.PathPrefix("/api").Handler(negroni.New(
		negroni.HandlerFunc(middleware.AuthMiddleware(app)),
		negroni.Wrap(apiBase)))
	share := apiBase.PathPrefix("/api").Subrouter()
	share.Methods("POST").Path("/urlshorter").HandlerFunc(controllers.Shorter)

	n := negroni.New()
	n.Use(negroni.NewRecovery())
	n.Use(negroni.HandlerFunc(middleware.ApiMiddleware))
	n.Use(c)
	n.Use(negronilogrus.NewCustomMiddleware(logrus.InfoLevel, &logrus.JSONFormatter{}, "textusm"))
	n.Use(gzip.Gzip(gzip.DefaultCompression))
	n.UseHandler(r)

	s := &http.Server{
		Addr:              fmt.Sprintf(":%s", env.Port),
		Handler:           n,
		ReadTimeout:       8 * time.Second,
		WriteTimeout:      8 * time.Second,
		MaxHeaderBytes:    1 << 20,
		ReadHeaderTimeout: 8 * time.Second,
	}
	err = s.ListenAndServe()

	if err != nil {
		return 1
	}

	return 0
}
