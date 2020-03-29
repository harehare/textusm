package item

import (
	"context"
	"testing"

	"github.com/harehare/textusm/api/middleware"
	"github.com/stretchr/testify/mock"
)

type MockRepository struct {
	mock.Mock
}

func (m *MockRepository) FindByID(ctx context.Context, userID, itemID string) (*Item, error) {
	ret := m.Called(ctx, userID, itemID)
	return ret.Get(0).(*Item), ret.Error(1)
}

func (m *MockRepository) Find(ctx context.Context, userID string, offset, limit int, isPublic bool) ([]*Item, error) {
	ret := m.Called(ctx, userID, offset, limit, isPublic)
	return ret.Get(0).([]*Item), ret.Error(1)
}

func (m *MockRepository) Save(ctx context.Context, userID string, item *Item) (*Item, error) {
	ret := m.Called(ctx, userID, item)
	return ret.Get(0).(*Item), ret.Error(1)
}

func (m *MockRepository) Delete(ctx context.Context, userID string, itemID string) error {
	ret := m.Called(ctx, userID, itemID)
	return ret.Error(0)
}

func TestFindDiagrams(t *testing.T) {
	mockRepo := new(MockRepository)
	ctx := context.Background()
	ctx = context.WithValue(ctx, middleware.UIDKey, "testID")

	encryptKey = []byte("000000000X000000000X000000000X12")
	baseText := "test"
	text, err := Encrypt(encryptKey, baseText)

	if err != nil {
		t.Fatal("failed test")
	}

	item := Item{ID: "id", Text: text}
	items := []*Item{&item}

	mockRepo.On("Find", ctx, "testID", 0, 10, false).Return(items, nil)

	service := NewService(mockRepo)
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
	mockRepo := new(MockRepository)
	ctx := context.Background()
	ctx = context.WithValue(ctx, middleware.UIDKey, "userID")

	encryptKey = []byte("000000000X000000000X000000000X12")
	baseText := "test"
	text, err := Encrypt(encryptKey, baseText)

	if err != nil {
		t.Fatal("failed test")
	}

	item := Item{ID: "id", Text: text}

	mockRepo.On("FindByID", ctx, "userID", "testID").Return(&item, nil)

	service := NewService(mockRepo)
	diagram, err := service.FindDiagram(ctx, "testID")

	if err != nil || diagram == nil || diagram.Text != baseText {
		t.Fatal("failed FindDiagram")
	}
}

func TestSaveDiagram(t *testing.T) {
	mockRepo := new(MockRepository)
	ctx := context.Background()
	ctx = context.WithValue(ctx, middleware.UIDKey, "userID")

	baseText := "test"
	item := Item{ID: "id", Text: baseText}

	mockRepo.On("Save", ctx, "userID", &item).Return(&item, nil)

	service := NewService(mockRepo)
	diagram, err := service.SaveDiagram(ctx, &item)

	if err != nil || diagram == nil || diagram.Text == baseText {
		t.Fatal("failed SaveDiagram")
	}
}

func TestDeleteDiagram(t *testing.T) {
	mockRepo := new(MockRepository)
	ctx := context.Background()
	ctx = context.WithValue(ctx, middleware.UIDKey, "userID")

	mockRepo.On("Delete", ctx, "userID", "testID").Return(nil)

	service := NewService(mockRepo)
	err := service.DeleteDiagram(ctx, "testID")

	if err != nil {
		t.Fatal("failed DeleteDiagram")
	}
}
