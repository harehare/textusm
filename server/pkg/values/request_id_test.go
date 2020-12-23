package values

import (
	"context"
	"testing"
)

func TestGetRequestID(t *testing.T) {
	ctx := context.Background()
	ctx = WithRequestID(ctx, "test")

	if GetRequestID(ctx) != "test" {
		t.Fatal("Failed GetRequestID")
	}
}
