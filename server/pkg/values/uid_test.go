package values

import (
	"context"
	"testing"
)

func TestGetUid(t *testing.T) {
	ctx := context.Background()
	ctx = WithUID(ctx, "test")

	if GetUID(ctx) != "test" {
		t.Fatal("Failed GetUid")
	}
}
