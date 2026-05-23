package gistitem

import (
	"context"
	"errors"
	"testing"

	"github.com/harehare/textusm/internal/context/values"
	"github.com/harehare/textusm/internal/domain/model/gistitem"
	"github.com/samber/mo"
	"github.com/stretchr/testify/mock"
)

type MockGistItemRepository struct {
	mock.Mock
}

func (m *MockGistItemRepository) FindByID(ctx context.Context, userID string, gistID string) mo.Result[*gistitem.GistItem] {
	ret := m.Called(ctx, userID, gistID)
	return ret.Get(0).(mo.Result[*gistitem.GistItem])
}

func (m *MockGistItemRepository) Find(ctx context.Context, userID string, offset, limit int) mo.Result[[]*gistitem.GistItem] {
	ret := m.Called(ctx, userID, offset, limit)
	return ret.Get(0).(mo.Result[[]*gistitem.GistItem])
}

func (m *MockGistItemRepository) Save(ctx context.Context, userID string, item *gistitem.GistItem) mo.Result[*gistitem.GistItem] {
	ret := m.Called(ctx, userID, item)
	return ret.Get(0).(mo.Result[*gistitem.GistItem])
}

func (m *MockGistItemRepository) Delete(ctx context.Context, userID string, itemID string) mo.Result[bool] {
	ret := m.Called(ctx, userID, itemID)
	return ret.Get(0).(mo.Result[bool])
}

type MockTransaction struct {
	mock.Mock
}

func (m *MockTransaction) Do(ctx context.Context, fn func(ctx context.Context) error) error {
	return fn(ctx)
}

func newTestService(repo *MockGistItemRepository, tx *MockTransaction) *Service {
	return NewService(repo, tx, "DUMMY_ID", "DUMMY_SECRET")
}

func authenticatedCtx() context.Context {
	return values.WithUID(context.Background(), "userID")
}

func TestFindGistItems(t *testing.T) {
	repo := new(MockGistItemRepository)
	tx := new(MockTransaction)
	ctx := authenticatedCtx()

	item := gistitem.New().WithID("id").WithURL("https://gist.github.com/test").Build().OrEmpty()
	items := []*gistitem.GistItem{item}

	repo.On("Find", ctx, "userID", 0, 10).Return(mo.Ok(items))

	svc := newTestService(repo, tx)
	ret := svc.Find(ctx, 0, 10)

	if ret.IsError() {
		t.Fatalf("Find() error: %v", ret.Error())
	}
	if len(ret.OrEmpty()) != 1 {
		t.Errorf("Find() returned %d items, want 1", len(ret.OrEmpty()))
	}
}

func TestFindGistItemsUnauthenticated(t *testing.T) {
	repo := new(MockGistItemRepository)
	tx := new(MockTransaction)
	ctx := context.Background()

	svc := newTestService(repo, tx)
	ret := svc.Find(ctx, 0, 10)

	if ret.IsOk() {
		t.Error("Find() without auth should return error")
	}
}

func TestFindGistItemsRepositoryError(t *testing.T) {
	repo := new(MockGistItemRepository)
	tx := new(MockTransaction)
	ctx := authenticatedCtx()

	repo.On("Find", ctx, "userID", 0, 10).Return(mo.Err[[]*gistitem.GistItem](errors.New("db error")))

	svc := newTestService(repo, tx)
	ret := svc.Find(ctx, 0, 10)

	if ret.IsOk() {
		t.Error("Find() should propagate repository error")
	}
}

func TestFindGistItemByID(t *testing.T) {
	repo := new(MockGistItemRepository)
	tx := new(MockTransaction)
	ctx := authenticatedCtx()

	item := gistitem.New().WithID("gist-id").Build().OrEmpty()
	repo.On("FindByID", ctx, "userID", "gist-id").Return(mo.Ok(item))

	svc := newTestService(repo, tx)
	ret := svc.FindByID(ctx, "gist-id")

	if ret.IsError() {
		t.Fatalf("FindByID() error: %v", ret.Error())
	}
	if ret.OrEmpty().ID() != "gist-id" {
		t.Errorf("FindByID() ID = %q, want %q", ret.OrEmpty().ID(), "gist-id")
	}
}

func TestFindGistItemByIDUnauthenticated(t *testing.T) {
	repo := new(MockGistItemRepository)
	tx := new(MockTransaction)

	svc := newTestService(repo, tx)
	ret := svc.FindByID(context.Background(), "gist-id")

	if ret.IsOk() {
		t.Error("FindByID() without auth should return error")
	}
}

func TestFindGistItemByIDNotFound(t *testing.T) {
	repo := new(MockGistItemRepository)
	tx := new(MockTransaction)
	ctx := authenticatedCtx()

	repo.On("FindByID", ctx, "userID", "missing").Return(mo.Err[*gistitem.GistItem](errors.New("not found")))

	svc := newTestService(repo, tx)
	ret := svc.FindByID(ctx, "missing")

	if ret.IsOk() {
		t.Error("FindByID() for missing item should return error")
	}
}

func TestSaveGistItem(t *testing.T) {
	repo := new(MockGistItemRepository)
	tx := new(MockTransaction)
	ctx := authenticatedCtx()

	item := gistitem.New().WithID("id").WithURL("https://gist.github.com/save").Build().OrEmpty()
	repo.On("Save", ctx, "userID", item).Return(mo.Ok(item))

	svc := newTestService(repo, tx)
	ret := svc.Save(ctx, item)

	if ret.IsError() {
		t.Fatalf("Save() error: %v", ret.Error())
	}
	if ret.OrEmpty().ID() != "id" {
		t.Errorf("Save() returned wrong item")
	}
}

func TestSaveGistItemUnauthenticated(t *testing.T) {
	repo := new(MockGistItemRepository)
	tx := new(MockTransaction)

	item := gistitem.New().WithID("id").Build().OrEmpty()
	svc := newTestService(repo, tx)
	ret := svc.Save(context.Background(), item)

	if ret.IsOk() {
		t.Error("Save() without auth should return error")
	}
}

func TestSaveGistItemRepositoryError(t *testing.T) {
	repo := new(MockGistItemRepository)
	tx := new(MockTransaction)
	ctx := authenticatedCtx()

	item := gistitem.New().WithID("id").Build().OrEmpty()
	repo.On("Save", ctx, "userID", item).Return(mo.Err[*gistitem.GistItem](errors.New("save failed")))

	svc := newTestService(repo, tx)
	ret := svc.Save(ctx, item)

	if ret.IsOk() {
		t.Error("Save() should propagate repository error")
	}
}

func TestDeleteGistItem(t *testing.T) {
	repo := new(MockGistItemRepository)
	tx := new(MockTransaction)
	ctx := authenticatedCtx()

	repo.On("Delete", ctx, "userID", "gist-id").Return(mo.Ok(true))

	svc := newTestService(repo, tx)
	ret := svc.Delete(ctx, "gist-id")

	if ret.IsError() {
		t.Fatalf("Delete() error: %v", ret.Error())
	}
	if !ret.OrEmpty() {
		t.Error("Delete() should return true on success")
	}
}

func TestDeleteGistItemUnauthenticated(t *testing.T) {
	repo := new(MockGistItemRepository)
	tx := new(MockTransaction)

	svc := newTestService(repo, tx)
	ret := svc.Delete(context.Background(), "gist-id")

	if ret.IsOk() {
		t.Error("Delete() without auth should return error")
	}
}

func TestDeleteGistItemRepositoryError(t *testing.T) {
	repo := new(MockGistItemRepository)
	tx := new(MockTransaction)
	ctx := authenticatedCtx()

	repo.On("Delete", ctx, "userID", "gist-id").Return(mo.Err[bool](errors.New("delete failed")))

	svc := newTestService(repo, tx)
	ret := svc.Delete(ctx, "gist-id")

	if ret.IsOk() {
		t.Error("Delete() should propagate repository error")
	}
}
