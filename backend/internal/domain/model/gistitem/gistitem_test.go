package gistitem

import (
	"testing"
	"time"

	"github.com/samber/mo"
)

func TestBuild(t *testing.T) {
	d := New().WithID("id").Build()

	if d.IsError() {
		t.Fatal("Failed build")
	}

	if d.OrEmpty().id != "id" {
		t.Fatal("Failed id build")
	}
}

func TestBuildGeneratesUUIDForEmptyID(t *testing.T) {
	item := New().WithID("").Build().OrEmpty()
	if item.ID() == "" {
		t.Error("WithID(\"\") should auto-generate a UUID")
	}
}

func TestBuildAllFields(t *testing.T) {
	now := time.Now().Truncate(time.Second)
	thumbnail := mo.Some("thumb-data")

	item := New().
		WithID("test-id").
		WithURL("https://gist.github.com/test").
		WithTitle("Test Title").
		WithThumbnail(thumbnail).
		WithDiagramString("USER_STORY_MAP").
		WithIsBookmark(true).
		WithCreatedAt(now).
		WithUpdatedAt(now).
		Build()

	if item.IsError() {
		t.Fatalf("Build() error: %v", item.Error())
	}

	g := item.OrEmpty()
	if g.ID() != "test-id" {
		t.Errorf("ID() = %q, want %q", g.ID(), "test-id")
	}
	if g.URL() != "https://gist.github.com/test" {
		t.Errorf("URL() = %q", g.URL())
	}
	if g.Title() != "Test Title" {
		t.Errorf("Title() = %q", g.Title())
	}
	if !g.IsBookmark() {
		t.Error("IsBookmark() should be true")
	}
	if g.CreatedAt() != now {
		t.Errorf("CreatedAt() = %v, want %v", g.CreatedAt(), now)
	}
}

func TestThumbnailPresent(t *testing.T) {
	item := New().WithID("id").WithThumbnail(mo.Some("thumb")).Build().OrEmpty()
	if item.Thumbnail() == nil || *item.Thumbnail() != "thumb" {
		t.Error("Thumbnail() should return pointer to thumbnail string")
	}
}

func TestThumbnailAbsent(t *testing.T) {
	item := New().WithID("id").WithThumbnail(mo.None[string]()).Build().OrEmpty()
	if item.Thumbnail() != nil {
		t.Error("Thumbnail() should return nil when absent")
	}
}

func TestBookmark(t *testing.T) {
	item := New().WithID("id").WithIsBookmark(false).Build().OrEmpty()
	if item.IsBookmark() {
		t.Error("initial IsBookmark should be false")
	}

	item.Bookmark(true)
	if !item.IsBookmark() {
		t.Error("Bookmark(true) should set IsBookmark to true")
	}

	item.Bookmark(false)
	if item.IsBookmark() {
		t.Error("Bookmark(false) should set IsBookmark to false")
	}
}

func TestMapToGistItemSuccess(t *testing.T) {
	now := time.Now().Truncate(time.Second)
	m := map[string]interface{}{
		"ID":         "gist-id",
		"URL":        "https://gist.github.com/example",
		"Title":      "My Gist",
		"Thumbnail":  "thumb",
		"Diagram":    "USER_STORY_MAP",
		"IsBookmark": false,
		"CreatedAt":  now,
		"UpdatedAt":  now,
	}

	result := MapToGistItem(m)
	if result.IsError() {
		t.Fatalf("MapToGistItem() error: %v", result.Error())
	}

	item := result.OrEmpty()
	if item.ID() != "gist-id" {
		t.Errorf("ID() = %q, want %q", item.ID(), "gist-id")
	}
	if item.URL() != "https://gist.github.com/example" {
		t.Errorf("URL() = %q", item.URL())
	}
}

func TestMapToGistItemNilThumbnail(t *testing.T) {
	now := time.Now()
	m := map[string]interface{}{
		"ID":         "id",
		"URL":        "https://gist.github.com/test",
		"Title":      "title",
		"Thumbnail":  nil,
		"Diagram":    "MIND_MAP",
		"IsBookmark": true,
		"CreatedAt":  now,
		"UpdatedAt":  now,
	}

	result := MapToGistItem(m)
	if result.IsError() {
		t.Fatalf("MapToGistItem() with nil thumbnail error: %v", result.Error())
	}
	if result.OrEmpty().Thumbnail() != nil {
		t.Error("Thumbnail should be nil when map value is nil")
	}
}

func TestMapToGistItemMissingFields(t *testing.T) {
	tests := []struct {
		name    string
		missing string
		m       map[string]interface{}
	}{
		{
			"missing ID",
			"ID",
			map[string]interface{}{"URL": "u", "Title": "t", "Diagram": "d", "IsBookmark": false, "CreatedAt": time.Now(), "UpdatedAt": time.Now()},
		},
		{
			"missing URL",
			"URL",
			map[string]interface{}{"ID": "i", "Title": "t", "Diagram": "d", "IsBookmark": false, "CreatedAt": time.Now(), "UpdatedAt": time.Now()},
		},
		{
			"missing Title",
			"Title",
			map[string]interface{}{"ID": "i", "URL": "u", "Diagram": "d", "IsBookmark": false, "CreatedAt": time.Now(), "UpdatedAt": time.Now()},
		},
		{
			"missing Diagram",
			"Diagram",
			map[string]interface{}{"ID": "i", "URL": "u", "Title": "t", "IsBookmark": false, "CreatedAt": time.Now(), "UpdatedAt": time.Now()},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := MapToGistItem(tt.m)
			if result.IsOk() {
				t.Errorf("MapToGistItem() should fail when %s is missing", tt.missing)
			}
		})
	}
}

func TestToMap(t *testing.T) {
	now := time.Now().Truncate(time.Second)
	item := New().
		WithID("id").
		WithURL("https://example.com").
		WithTitle("title").
		WithDiagramString("KANBAN").
		WithIsBookmark(true).
		WithCreatedAt(now).
		WithUpdatedAt(now).
		Build().OrEmpty()

	m := item.ToMap()
	if m["ID"] != "id" {
		t.Errorf("ToMap()[ID] = %v", m["ID"])
	}
	if m["URL"] != "https://example.com" {
		t.Errorf("ToMap()[URL] = %v", m["URL"])
	}
	if m["IsBookmark"] != true {
		t.Errorf("ToMap()[IsBookmark] = %v", m["IsBookmark"])
	}
}
