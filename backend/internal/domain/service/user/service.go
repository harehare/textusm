package user

import (
	"context"

	"github.com/harehare/textusm/internal/context/values"
	userRepo "github.com/harehare/textusm/internal/domain/repository/user"
	e "github.com/harehare/textusm/internal/error"
	"github.com/harehare/textusm/internal/github"
)

type Service struct {
	userRepo     userRepo.UserRepository
	clientID     github.ClientID
	clientSecret github.ClientSecret
}

func NewService(u userRepo.UserRepository, clientID github.ClientID, clientSecret github.ClientSecret) *Service {
	return &Service{
		userRepo:     u,
		clientID:     clientID,
		clientSecret: clientSecret,
	}
}

func IsAuthenticated(ctx context.Context) error {
	userID := values.GetUID(ctx)

	if userID.IsAbsent() {
		return e.NoAuthorizationError(e.ErrNotAuthorization)
	}

	return nil
}

func (s *Service) RevokeGistToken(ctx context.Context, accessToken string) error {
	if err := IsAuthenticated(ctx); err != nil {
		return err
	}

	return s.userRepo.RevokeGistToken(ctx, string(s.clientID), string(s.clientSecret), accessToken)
}

func (s *Service) RevokeToken(ctx context.Context) error {
	if err := IsAuthenticated(ctx); err != nil {
		return err
	}

	return s.userRepo.RevokeToken(ctx)
}
