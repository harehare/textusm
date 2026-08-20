package handler

import (
	"log/slog"
	"net/http"
	"os"
	"time"

	gqlHandler "github.com/99designs/gqlgen/graphql/handler"
	"github.com/99designs/gqlgen/graphql/handler/extension"
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

func NewHandler(env *config.Env, config *config.Config, resolvers *resolver.Resolver, restApi *api.Api, logger *slog.Logger) (*chi.Mux, error) {
	r := chi.NewRouter()
	r.Use(chiMiddleware.Compress(5))
	r.Use(chiMiddleware.RequestID)
	// Fall back to the raw TCP peer, then prefer the IP Render's edge proxy
	// appends to X-Forwarded-For (the only hop between us and the client).
	r.Use(chiMiddleware.ClientIPFromRemoteAddr)
	r.Use(chiMiddleware.ClientIPFromXFFTrustedProxies(1))
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
		if _, err := rw.Write([]byte(env.Version)); err != nil {
			slog.Error("failed to write version response", "error", err)
		}
	})

	r.Route("/api/v1", func(r chi.Router) {
		r.Use(chiMiddleware.AllowContentType("application/json"))
		r.Use(middleware.IPMiddleware())
		r.Use(cors)

		r.Route("/", func(r chi.Router) {
			r.Use(middleware.AuthMiddleware(config.FirebaseApp))
			r.Use(httprate.LimitBy(10, 1*time.Minute, keyByResolvedIP))
			r.Route("/token", func(r chi.Router) {
				r.Delete("/revoke", restApi.RevokeGistToken)
				r.Delete("/gist/revoke", restApi.RevokeGistToken)
			})
		})
	})

	r.Route("/graphql", func(r chi.Router) {
		r.Use(chiMiddleware.AllowContentType("application/json"))
		r.Use(middleware.AuthMiddleware(config.FirebaseApp))
		r.Use(middleware.IPMiddleware())
		r.Use(cors)
		r.Use(httprate.LimitBy(100, 1*time.Minute, keyByResolvedIP))

		graphql := gqlHandler.New(resolver.NewExecutableSchema(resolver.Config{Resolvers: resolvers}))
		graphql.AddTransport(transport.Options{})
		graphql.AddTransport(transport.POST{})
		if os.Getenv("GO_ENV") != "production" {
			graphql.Use(extension.Introspection{})
		}
		r.Handle("/", graphql)
	})

	slog.SetDefault(logger)

	return r, nil
}

// keyByResolvedIP rate-limits by the IP resolved via ClientIPFromRemoteAddr /
// ClientIPFromXFFTrustedProxies, rather than the spoofable r.RemoteAddr used
// by the deprecated httprate.LimitByIP.
func keyByResolvedIP(r *http.Request) (string, error) {
	return httprate.CanonicalizeIP(chiMiddleware.GetClientIP(r.Context())), nil
}
