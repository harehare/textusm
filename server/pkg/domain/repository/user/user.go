package user

import (
	"context"

	u "github.com/harehare/textusm/pkg/domain/model/user"
)

type UserRepository interface {
	Find(ctx context.Context, uid string) (*u.User, error)
}
