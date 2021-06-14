package user

import (
	"context"

	firebase "firebase.google.com/go"
	"github.com/harehare/textusm/pkg/domain/model/user"
	userRepo "github.com/harehare/textusm/pkg/domain/repository/user"
)

type FirebaseUserRepository struct {
	app *firebase.App
}

func NewFirebaseUserRepository(app *firebase.App) userRepo.UserRepository {
	return &FirebaseUserRepository{app: app}
}

func (r *FirebaseUserRepository) Find(ctx context.Context, uid string) (*user.User, error) {
	client, err := r.app.Auth(ctx)
	if err != nil {
		return nil, err
	}
	u, err := client.GetUser(ctx, uid)
	if err != nil {
		return nil, err
	}
	user := user.NewUser(u)

	return &user, nil
}
