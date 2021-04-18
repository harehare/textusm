package repository

import (
	"context"

	firebase "firebase.google.com/go"
	"github.com/harehare/textusm/pkg/model"
)

type FirebaseUserRepository struct {
	app *firebase.App
}

func NewFirebaseUserRepository(app *firebase.App) UserRepository {
	return &FirebaseUserRepository{app: app}
}

func (r *FirebaseUserRepository) Find(ctx context.Context, uid string) (*model.User, error) {
	client, err := r.app.Auth(ctx)
	if err != nil {
		return nil, err
	}
	u, err := client.GetUser(ctx, uid)
	if err != nil {
		return nil, err
	}
	user := model.NewUser(u)

	return &user, nil
}
