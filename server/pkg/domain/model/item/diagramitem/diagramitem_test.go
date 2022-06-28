package diagramitem

import "testing"

func TestEncryptedTextBuild(t *testing.T) {
	d := New().WithID("id").WithEncryptedText("encryptedText").Build()

	if d.IsError() {
		t.Fatal("Failed build")
	}

	if d.OrEmpty().id != "id" {
		t.Fatal("Failed id build")
	}

	if d.OrEmpty().encryptedText != "encryptedText" {
		t.Fatal("Failed text build")
	}
}

func TestPlainTextBuild(t *testing.T) {
	encryptKey = []byte("000000000X000000000X000000000X12")
	d := New().WithID("id").WithPlainText("plainText").Build()

	if d.IsError() {
		t.Fatal("Failed build")
	}

	if d.OrEmpty().id != "id" {
		t.Fatal("Failed id build")
	}

	if d.OrEmpty().encryptedText == "plainText" {
		t.Fatal("Failed text build")
	}

	if d.OrEmpty().Text() != "plainText" {
		t.Fatal("Failed Text()")
	}
}
