package handler

import (
	"net/http"
	"os"
	"time"

	gqlHandler "github.com/99designs/gqlgen/graphql/handler"
	"github.com/99designs/gqlgen/graphql/handler/extension"
	"github.com/99designs/gqlgen/graphql/handler/lru"
	"github.com/99designs/gqlgen/graphql/handler/transport"
	"github.com/go-chi/chi/v5"
	chiMiddleware "github.com/go-chi/chi/v5/middleware"
	"github.com/go-chi/cors"
	"github.com/go-chi/httprate"
	"github.com/harehare/textusm/internal/config"
	"github.com/harehare/textusm/internal/presentation/api"
	"github.com/harehare/textusm/internal/presentation/api/middleware"
	resolver "github.com/harehare/textusm/internal/presentation/graphql"
)

func NewHandler(env *config.Env, config *config.Config, resolvers *resolver.Resolver, restApi *api.Api) (*chi.Mux, error) {

	r := chi.NewRouter()
	r.Use(chiMiddleware.Compress(5))
	r.Use(chiMiddleware.RequestID)
	r.Use(chiMiddleware.RealIP)
	r.Use(chiMiddleware.Logger)
	r.Use(chiMiddleware.Recoverer)
	r.Use(chiMiddleware.Heartbeat("/healthcheck"))

	cors := cors.Handler(cors.Options{
		AllowedOrigins:   []string{"https://app.textusm.com", "http://localhost:3000", "https://localhost:3000", "http://localhost:3001", "https://localhost:3001"},
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

	r.Route("/api/v1", func(r chi.Router) {
		r.Use(chiMiddleware.AllowContentType("application/json"))
		r.Use(middleware.IPMiddleware())
		r.Use(cors)

		r.Route("/settings", func(r chi.Router) {
			r.Use(httprate.LimitByIP(10, 1*time.Minute))
			r.Get("/usable-font-list", restApi.UsableFontList)
		})

		r.Route("/", func(r chi.Router) {
			r.Use(middleware.AuthMiddleware(config.FirebaseApp))
			r.Use(httprate.LimitByIP(10, 1*time.Minute))
			r.Route("/token", func(r chi.Router) {
				r.Delete("/gist/revoke", restApi.RevokeGistToken)
			})
		})
	})

	r.Route("/graphql", func(r chi.Router) {
		r.Use(chiMiddleware.AllowContentType("application/json"))
		r.Use(middleware.AuthMiddleware(config.FirebaseApp))
		r.Use(middleware.IPMiddleware())
		r.Use(cors)
		r.Use(httprate.LimitByIP(100, 1*time.Minute))

		graphql := gqlHandler.New(resolver.NewExecutableSchema(resolver.Config{Resolvers: resolvers}))
		graphql.AddTransport(transport.Options{})
		graphql.AddTransport(transport.POST{})
		graphql.SetQueryCache(lru.New(100))
		if os.Getenv("GO_ENV") != "production" {
			graphql.Use(extension.Introspection{})
		}
		r.Handle("/", graphql)
	})

	return r, nil
}
