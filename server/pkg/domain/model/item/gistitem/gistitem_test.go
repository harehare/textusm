package gistitem

import "testing"

func TestBuild(t *testing.T) {
	d, err := New().WithID("id").Build()

	if err != nil {
		t.Fatal("Failed build")
	}

	if d.id != "id" {
		t.Fatal("Failed id build")
	}
}
