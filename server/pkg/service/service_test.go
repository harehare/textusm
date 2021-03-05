package service

import (
	"context"
	"testing"

	"github.com/harehare/textusm/pkg/item"
	"github.com/harehare/textusm/pkg/values"
	"github.com/stretchr/testify/mock"
)

type MockItemRepository struct {
	mock.Mock
}

type MockShareRepository struct {
	mock.Mock
}

func (m *MockItemRepository) FindByID(ctx context.Context, userID, itemID string, isPublic bool) (*item.Item, error) {
	ret := m.Called(ctx, userID, itemID, isPublic)
	return ret.Get(0).(*item.Item), ret.Error(1)
}

func (m *MockItemRepository) Find(ctx context.Context, userID string, offset, limit int, isPublic bool) ([]*item.Item, error) {
	ret := m.Called(ctx, userID, offset, limit, isPublic)
	return ret.Get(0).([]*item.Item), ret.Error(1)
}

func (m *MockItemRepository) Save(ctx context.Context, userID string, i *item.Item, isPublic bool) (*item.Item, error) {
	ret := m.Called(ctx, userID, i, isPublic)
	return ret.Get(0).(*item.Item), ret.Error(1)
}

func (m *MockItemRepository) Delete(ctx context.Context, userID string, itemID string, isPublic bool) error {
	ret := m.Called(ctx, userID, itemID, isPublic)
	return ret.Error(0)
}

func (m *MockShareRepository) FindByID(ctx context.Context, hashKey string) (*item.Item, error) {
	ret := m.Called(ctx, hashKey)
	return ret.Get(0).(*item.Item), ret.Error(1)
}

func (m *MockShareRepository) Save(ctx context.Context, hashKey string, item *item.Item) error {
	ret := m.Called(ctx, hashKey, item)
	return ret.Error(0)
}

func TestFindDiagrams(t *testing.T) {
	mockItemRepo := new(MockItemRepository)
	mockShareRepo := new(MockShareRepository)
	ctx := context.Background()
	ctx = values.WithUID(ctx, "userID")

	encryptKey = []byte("000000000X000000000X000000000X12")
	baseText := "test"
	text, err := Encrypt(encryptKey, baseText)

	if err != nil {
		t.Fatal("failed test")
	}

	i := item.Item{ID: "id", Text: text}
	items := []*item.Item{&i}

	mockItemRepo.On("Find", ctx, "userID", 0, 10, false).Return(items, nil)

	service := NewService(mockItemRepo, mockShareRepo)
	diagrams, err := service.FindDiagrams(ctx, 0, 10, false)

	if err != nil {
		t.Fatal("failed FindDiagrams")
	}

	for _, diagram := range diagrams {
		if diagram.Text != baseText {
			t.Fatal("failed FindDiagrams")
		}
	}
}

func TestFindDiagram(t *testing.T) {
	mockItemRepo := new(MockItemRepository)
	mockShareRepo := new(MockShareRepository)
	ctx := context.Background()
	ctx = values.WithUID(ctx, "userID")

	encryptKey = []byte("000000000X000000000X000000000X12")
	baseText := "test"
	text, err := Encrypt(encryptKey, baseText)

	if err != nil {
		t.Fatal("failed test")
	}

	item := item.Item{ID: "id", Text: text}

	mockItemRepo.On("FindByID", ctx, "userID", "testID", false).Return(&item, nil)

	service := NewService(mockItemRepo, mockShareRepo)
	diagram, err := service.FindDiagram(ctx, "testID", false)

	if err != nil || diagram == nil || diagram.Text != baseText {
		t.Fatal("failed FindDiagram")
	}
}

func TestSaveDiagram(t *testing.T) {
	mockItemRepo := new(MockItemRepository)
	mockShareRepo := new(MockShareRepository)
	ctx := context.Background()
	ctx = values.WithUID(ctx, "userID")

	baseText := "test"
	item := item.Item{ID: "", Text: baseText}

	mockItemRepo.On("Save", ctx, "userID", &item, false).Return(&item, nil)

	service := NewService(mockItemRepo, mockShareRepo)
	diagram, err := service.SaveDiagram(ctx, &item, false)

	if err != nil || diagram == nil || diagram.Text != baseText {
		t.Fatal("failed SaveDiagram")
	}
}

func TestDeleteDiagram(t *testing.T) {
	mockItemRepo := new(MockItemRepository)
	mockShareRepo := new(MockShareRepository)
	ctx := context.Background()
	ctx = values.WithUID(ctx, "userID")

	mockItemRepo.On("Delete", ctx, "userID", "testID", false).Return(nil)

	service := NewService(mockItemRepo, mockShareRepo)
	err := service.DeleteDiagram(ctx, "testID", false)

	if err != nil {
		t.Fatal("failed DeleteDiagram")
	}
}
