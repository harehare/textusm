package user

import (
	"bytes"
	"context"
	"fmt"
	"net/http"
	"time"

	firebase "firebase.google.com/go/v4"
	"github.com/harehare/textusm/internal/config"
	"github.com/harehare/textusm/internal/domain/model/user"
	userRepo "github.com/harehare/textusm/internal/domain/repository/user"
	"github.com/samber/mo"
)

type FirebaseUserRepository struct {
	app *firebase.App
}

func NewFirebaseUserRepository(config *config.Config) userRepo.UserRepository {
	return &FirebaseUserRepository{app: config.FirebaseApp}
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

func (r *FirebaseUserRepository) RevokeToken(ctx context.Context, clientID, clientSecret, accessToken string) error {
	client := &http.Client{Timeout: time.Duration(30) * time.Second}
	body := `{"access_token":"` + accessToken + `"}`
	req, err := http.NewRequest("DELETE", fmt.Sprintf("https://api.github.com/applications/%s/token", clientID), bytes.NewBuffer([]byte(body)))
	if err != nil {
		return err
	}
	req.SetBasicAuth(clientID, clientSecret)
	req.Header.Add("Accept", "application/vnd.github.v3+json")
	res, err := client.Do(req)

	if err != nil {
		return err
	}
	defer res.Body.Close()

	return nil
}
