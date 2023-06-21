package values

import (
	"context"
	"testing"
)

func TestGetUid(t *testing.T) {
	ctx := context.Background()
	v := "test"
	ctx = WithUID(ctx, v)
	r := GetUID(ctx)

	if r.OrEmpty() != v {
		t.Fatal("Failed GetUid")
	}
}
