package middleware

import (
	"context"
	"net/http"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"
)

func LoggingMiddleware(w http.ResponseWriter, r *http.Request, next http.HandlerFunc) {
	uuidValue, _ := uuid.NewUUID()
	requestID := uuidValue.String()
	ctx := context.WithValue(r.Context(), RequestIDKey, requestID)
	log.Info().Str("request_id", requestID).Msg("Start request")
	next(w, r.WithContext(ctx))
	log.Info().Str("request_id", requestID).Msg("End request")
}
