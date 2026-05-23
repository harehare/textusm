package settings

import (
	"context"
	"errors"
	"testing"

	"github.com/harehare/textusm/internal/context/values"
	settingsModel "github.com/harehare/textusm/internal/domain/model/settings"
	v "github.com/harehare/textusm/internal/domain/values"
	"github.com/samber/mo"
	"github.com/stretchr/testify/mock"
)

type MockSettingsRepository struct {
	mock.Mock
}

func (m *MockSettingsRepository) Find(ctx context.Context, userID string, diagram v.Diagram) mo.Result[*settingsModel.Settings] {
	ret := m.Called(ctx, userID, diagram)
	return ret.Get(0).(mo.Result[*settingsModel.Settings])
}

func (m *MockSettingsRepository) Save(ctx context.Context, userID string, diagram v.Diagram, s *settingsModel.Settings) mo.Result[*settingsModel.Settings] {
	ret := m.Called(ctx, userID, diagram, s)
	return ret.Get(0).(mo.Result[*settingsModel.Settings])
}

type MockTransaction struct {
	mock.Mock
}

func (m *MockTransaction) Do(ctx context.Context, fn func(ctx context.Context) error) error {
	return fn(ctx)
}

func newTestService(repo *MockSettingsRepository, tx *MockTransaction) *Service {
	return NewService(repo, tx, "DUMMY_ID", "DUMMY_SECRET")
}

func authenticatedCtx() context.Context {
	return values.WithUID(context.Background(), "userID")
}

func TestFindSettings(t *testing.T) {
	repo := new(MockSettingsRepository)
	tx := new(MockTransaction)
	ctx := authenticatedCtx()
	diagram := v.DiagramUserStoryMap

	s := &settingsModel.Settings{Font: "Roboto", Width: 1440, Height: 900}
	repo.On("Find", ctx, "userID", diagram).Return(mo.Ok(s))

	svc := newTestService(repo, tx)
	ret := svc.Find(ctx, diagram)

	if ret.IsError() {
		t.Fatalf("Find() error: %v", ret.Error())
	}
	if ret.OrEmpty().Font != "Roboto" {
		t.Errorf("Find() Font = %q, want %q", ret.OrEmpty().Font, "Roboto")
	}
}

func TestFindSettingsUnauthenticated(t *testing.T) {
	repo := new(MockSettingsRepository)
	tx := new(MockTransaction)

	svc := newTestService(repo, tx)
	ret := svc.Find(context.Background(), v.DiagramUserStoryMap)

	if ret.IsOk() {
		t.Error("Find() without auth should return error")
	}
}

func TestFindSettingsRepositoryError(t *testing.T) {
	repo := new(MockSettingsRepository)
	tx := new(MockTransaction)
	ctx := authenticatedCtx()
	diagram := v.DiagramMindMap

	repo.On("Find", ctx, "userID", diagram).Return(mo.Err[*settingsModel.Settings](errors.New("not found")))

	svc := newTestService(repo, tx)
	ret := svc.Find(ctx, diagram)

	if ret.IsOk() {
		t.Error("Find() should propagate repository error")
	}
}

func TestSaveSettings(t *testing.T) {
	repo := new(MockSettingsRepository)
	tx := new(MockTransaction)
	ctx := authenticatedCtx()
	diagram := v.DiagramKanban

	s := &settingsModel.Settings{Font: "Noto Sans", Width: 1280, Height: 720}
	repo.On("Save", ctx, "userID", diagram, s).Return(mo.Ok(s))

	svc := newTestService(repo, tx)
	ret := svc.Save(ctx, diagram, s)

	if ret.IsError() {
		t.Fatalf("Save() error: %v", ret.Error())
	}
	if ret.OrEmpty().Font != "Noto Sans" {
		t.Errorf("Save() Font = %q, want %q", ret.OrEmpty().Font, "Noto Sans")
	}
}

func TestSaveSettingsUnauthenticated(t *testing.T) {
	repo := new(MockSettingsRepository)
	tx := new(MockTransaction)

	s := &settingsModel.Settings{}
	svc := newTestService(repo, tx)
	ret := svc.Save(context.Background(), v.DiagramKanban, s)

	if ret.IsOk() {
		t.Error("Save() without auth should return error")
	}
}

func TestSaveSettingsRepositoryError(t *testing.T) {
	repo := new(MockSettingsRepository)
	tx := new(MockTransaction)
	ctx := authenticatedCtx()
	diagram := v.DiagramErDiagram

	s := &settingsModel.Settings{}
	repo.On("Save", ctx, "userID", diagram, s).Return(mo.Err[*settingsModel.Settings](errors.New("save failed")))

	svc := newTestService(repo, tx)
	ret := svc.Save(ctx, diagram, s)

	if ret.IsOk() {
		t.Error("Save() should propagate repository error")
	}
}

func TestFindMultipleDiagramTypes(t *testing.T) {
	diagrams := []v.Diagram{
		v.DiagramUserStoryMap,
		v.DiagramMindMap,
		v.DiagramKanban,
		v.DiagramErDiagram,
		v.DiagramGanttChart,
	}

	for _, diagram := range diagrams {
		t.Run(string(diagram), func(t *testing.T) {
			repo := new(MockSettingsRepository)
			tx := new(MockTransaction)
			ctx := authenticatedCtx()
			s := &settingsModel.Settings{Font: "Arial"}
			repo.On("Find", ctx, "userID", diagram).Return(mo.Ok(s))

			svc := newTestService(repo, tx)
			ret := svc.Find(ctx, diagram)
			if ret.IsError() {
				t.Fatalf("Find(%s) error: %v", diagram, ret.Error())
			}
		})
	}
}
