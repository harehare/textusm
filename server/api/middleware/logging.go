package middleware

import (
	"net/http"

	"github.com/google/uuid"
	"github.com/harehare/textusm/pkg/values"
	"github.com/rs/zerolog/log"
)

func LoggingMiddleware(w http.ResponseWriter, r *http.Request, next http.HandlerFunc) {
	uuidValue, _ := uuid.NewUUID()
	requestID := uuidValue.String()
	ctx := values.WithRequestID(r.Context(), requestID)
	log.Info().Str("request_id", requestID).Msg("Start request")
	next(w, r.WithContext(ctx))
	log.Info().Str("request_id", requestID).Msg("End request")
}
