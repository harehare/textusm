package user

import (
	"context"

	firebase "firebase.google.com/go/v4"
	"github.com/harehare/textusm/pkg/domain/model/user"
	userRepo "github.com/harehare/textusm/pkg/domain/repository/user"
	"github.com/samber/mo"
)

type FirebaseUserRepository struct {
	app *firebase.App
}

func NewFirebaseUserRepository(app *firebase.App) userRepo.UserRepository {
	return &FirebaseUserRepository{app: app}
}

func (r *FirebaseUserRepository) Find(ctx context.Context, uid string) mo.Result[*user.User] {
	client, err := r.app.Auth(ctx)
	if err != nil {
		return mo.Err[*user.User](err)
	}
	u, err := client.GetUser(ctx, uid)
	if err != nil {
		return mo.Err[*user.User](err)
	}
	user := user.NewUser(u)

	return mo.Ok(&user)
}
