package user

import (
	"context"
	"errors"
	"testing"

	"github.com/harehare/textusm/internal/context/values"
	userModel "github.com/harehare/textusm/internal/domain/model/user"
	"github.com/samber/mo"
	"github.com/stretchr/testify/mock"
)

type MockUserRepository struct {
	mock.Mock
}

func (m *MockUserRepository) Find(ctx context.Context, uid string) mo.Result[*userModel.User] {
	ret := m.Called(ctx, uid)
	return ret.Get(0).(mo.Result[*userModel.User])
}

func (m *MockUserRepository) RevokeGistToken(ctx context.Context, clientID, clientSecret, accessToken string) error {
	ret := m.Called(ctx, clientID, clientSecret, accessToken)
	if ret.Get(0) == nil {
		return nil
	}
	return ret.Get(0).(error)
}

func (m *MockUserRepository) RevokeToken(ctx context.Context) error {
	ret := m.Called(ctx)
	if ret.Get(0) == nil {
		return nil
	}
	return ret.Get(0).(error)
}

func authenticatedCtx() context.Context {
	return values.WithUID(context.Background(), "userID")
}

func TestIsAuthenticatedWithUID(t *testing.T) {
	ctx := authenticatedCtx()
	if err := IsAuthenticated(ctx); err != nil {
		t.Errorf("IsAuthenticated() with UID should return nil, got %v", err)
	}
}

func TestIsAuthenticatedWithoutUID(t *testing.T) {
	if err := IsAuthenticated(context.Background()); err == nil {
		t.Error("IsAuthenticated() without UID should return error")
	}
}

func TestRevokeGistTokenSuccess(t *testing.T) {
	repo := new(MockUserRepository)
	ctx := authenticatedCtx()

	repo.On("RevokeGistToken", ctx, "DUMMY_ID", "DUMMY_SECRET", "access-token").Return(nil)

	svc := NewService(repo, "DUMMY_ID", "DUMMY_SECRET")
	if err := svc.RevokeGistToken(ctx, "access-token"); err != nil {
		t.Errorf("RevokeGistToken() error = %v", err)
	}
}

func TestRevokeGistTokenUnauthenticated(t *testing.T) {
	repo := new(MockUserRepository)
	svc := NewService(repo, "DUMMY_ID", "DUMMY_SECRET")

	if err := svc.RevokeGistToken(context.Background(), "access-token"); err == nil {
		t.Error("RevokeGistToken() without auth should return error")
	}
}

func TestRevokeGistTokenRepositoryError(t *testing.T) {
	repo := new(MockUserRepository)
	ctx := authenticatedCtx()

	repo.On("RevokeGistToken", ctx, "DUMMY_ID", "DUMMY_SECRET", "bad-token").Return(errors.New("revoke failed"))

	svc := NewService(repo, "DUMMY_ID", "DUMMY_SECRET")
	if err := svc.RevokeGistToken(ctx, "bad-token"); err == nil {
		t.Error("RevokeGistToken() should propagate repository error")
	}
}

func TestRevokeTokenSuccess(t *testing.T) {
	repo := new(MockUserRepository)
	ctx := authenticatedCtx()

	repo.On("RevokeToken", ctx).Return(nil)

	svc := NewService(repo, "DUMMY_ID", "DUMMY_SECRET")
	if err := svc.RevokeToken(ctx); err != nil {
		t.Errorf("RevokeToken() error = %v", err)
	}
}

func TestRevokeTokenUnauthenticated(t *testing.T) {
	repo := new(MockUserRepository)
	svc := NewService(repo, "DUMMY_ID", "DUMMY_SECRET")

	if err := svc.RevokeToken(context.Background()); err == nil {
		t.Error("RevokeToken() without auth should return error")
	}
}

func TestRevokeTokenRepositoryError(t *testing.T) {
	repo := new(MockUserRepository)
	ctx := authenticatedCtx()

	repo.On("RevokeToken", ctx).Return(errors.New("revoke failed"))

	svc := NewService(repo, "DUMMY_ID", "DUMMY_SECRET")
	if err := svc.RevokeToken(ctx); err == nil {
		t.Error("RevokeToken() should propagate repository error")
	}
}
