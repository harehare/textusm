package gistitem

import "testing"

func TestBuild(t *testing.T) {
	d := New().WithID("id").Build()

	if d.IsError() {
		t.Fatal("Failed build")
	}

	if d.OrEmpty().id != "id" {
		t.Fatal("Failed id build")
	}
}
