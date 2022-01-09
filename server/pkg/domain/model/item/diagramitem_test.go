package item

import "testing"

func TestEncryptedTextBuild(t *testing.T) {
	d, err := NewDiagramItem().WithID("id").WithEncryptedText("encryptedText").Build()

	if err != nil {
		t.Fatal("Failed build")
	}

	if d.id != "id" {
		t.Fatal("Failed id build")
	}

	if d.encryptedText != "encryptedText" {
		t.Fatal("Failed text build")
	}
}

func TestPlainTextBuild(t *testing.T) {
	encryptKey = []byte("000000000X000000000X000000000X12")
	d, err := NewDiagramItem().WithID("id").WithPlainText("plainText").Build()

	if err != nil {
		t.Fatal("Failed build")
	}

	if d.id != "id" {
		t.Fatal("Failed id build")
	}

	if d.encryptedText == "plainText" {
		t.Fatal("Failed text build")
	}

	if d.Text() != "plainText" {
		t.Fatal("Failed Text()")
	}
}
