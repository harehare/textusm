package values

import (
	"context"
	"testing"
)

func TestGetIPPresent(t *testing.T) {
	ctx := context.Background()
	want := "192.168.0.1"
	ctx = WithIP(ctx, want)

	got := GetIP(ctx)
	if got.IsAbsent() {
		t.Fatal("GetIP() should return a present option")
	}
	if got.OrEmpty() != want {
		t.Errorf("GetIP() = %q, want %q", got.OrEmpty(), want)
	}
}

func TestGetIPAbsent(t *testing.T) {
	ctx := context.Background()
	got := GetIP(ctx)
	if got.IsPresent() {
		t.Errorf("GetIP() on empty context should be absent, got %q", got.OrEmpty())
	}
}

func TestWithIPOverwrite(t *testing.T) {
	ctx := context.Background()
	ctx = WithIP(ctx, "10.0.0.1")
	ctx = WithIP(ctx, "10.0.0.2")

	got := GetIP(ctx)
	if got.OrEmpty() != "10.0.0.2" {
		t.Errorf("WithIP() overwrite: got %q, want %q", got.OrEmpty(), "10.0.0.2")
	}
}

func TestGetIPDoesNotAffectUID(t *testing.T) {
	ctx := context.Background()
	ctx = WithUID(ctx, "user-123")
	ctx = WithIP(ctx, "127.0.0.1")

	uid := GetUID(ctx)
	if uid.OrEmpty() != "user-123" {
		t.Errorf("WithIP() should not affect UID, got %q", uid.OrEmpty())
	}

	ip := GetIP(ctx)
	if ip.OrEmpty() != "127.0.0.1" {
		t.Errorf("WithUID() should not affect IP, got %q", ip.OrEmpty())
	}
}
