package user

import (
	"context"

	u "github.com/harehare/textusm/pkg/domain/model/user"
	"github.com/samber/mo"
)

type UserRepository interface {
	Find(ctx context.Context, uid string) mo.Result[*u.User]
}
