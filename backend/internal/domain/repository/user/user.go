package user

import (
	"context"

	u "github.com/harehare/textusm/internal/domain/model/user"
	"github.com/samber/mo"
)

type UserRepository interface {
	Find(ctx context.Context, uid string) mo.Result[*u.User]
	RevokeToken(ctx context.Context, clientID, clientSecret, accessToken string) error
}
