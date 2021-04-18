package repository

import (
	"context"

	"github.com/harehare/textusm/pkg/model"
)

type UserRepository interface {
	Find(ctx context.Context, uid string) (*model.User, error)
}
