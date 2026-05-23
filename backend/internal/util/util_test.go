package util

import (
	"strings"
	"testing"
)

var testKey = []byte("000000000X000000000X000000000X12")

func TestEncryptDecryptRoundTrip(t *testing.T) {
	tests := []struct {
		name  string
		input string
	}{
		{"empty string", ""},
		{"short text", "hello"},
		{"unicode", "日本語テキスト"},
		{"long text", strings.Repeat("a", 1000)},
		{"special chars", "!@#$%^&*()_+-=[]{}|;':\",./<>?"},
		{"newlines", "line1\nline2\nline3"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			encrypted, err := Encrypt(testKey, tt.input)
			if err != nil {
				t.Fatalf("Encrypt() error = %v", err)
			}

			decrypted, err := Decrypt(testKey, encrypted)
			if err != nil {
				t.Fatalf("Decrypt() error = %v", err)
			}

			if decrypted != tt.input {
				t.Errorf("round-trip failed: got %q, want %q", decrypted, tt.input)
			}
		})
	}
}

func TestEncryptProducesUniqueOutput(t *testing.T) {
	plain := "same plaintext"
	enc1, err := Encrypt(testKey, plain)
	if err != nil {
		t.Fatalf("first Encrypt() error = %v", err)
	}
	enc2, err := Encrypt(testKey, plain)
	if err != nil {
		t.Fatalf("second Encrypt() error = %v", err)
	}
	if enc1 == enc2 {
		t.Error("Encrypt() should produce different ciphertext each call (random IV)")
	}
}

func TestDecryptWithWrongKey(t *testing.T) {
	encrypted, err := Encrypt(testKey, "secret")
	if err != nil {
		t.Fatalf("Encrypt() error = %v", err)
	}

	wrongKey := []byte("WRONGKEY0X000000000X000000000X12")
	decrypted, err := Decrypt(wrongKey, encrypted)
	if err == nil && decrypted == "secret" {
		t.Error("Decrypt() with wrong key should not return original plaintext")
	}
}

func TestDecryptInvalidBase64(t *testing.T) {
	_, err := Decrypt(testKey, "not-valid-base64!!!")
	if err == nil {
		t.Error("Decrypt() with invalid base64 should return error")
	}
}

func TestGenerateRandomString(t *testing.T) {
	lengths := []int{8, 16, 32, 64}

	for _, n := range lengths {
		s, err := GenerateRandomString(n)
		if err != nil {
			t.Fatalf("GenerateRandomString(%d) error = %v", n, err)
		}
		if len(s) != n {
			t.Errorf("GenerateRandomString(%d) length = %d, want %d", n, len(s), n)
		}
	}
}

func TestGenerateRandomStringUniqueness(t *testing.T) {
	seen := make(map[string]struct{})
	for range 10 {
		s, err := GenerateRandomString(32)
		if err != nil {
			t.Fatalf("GenerateRandomString() error = %v", err)
		}
		if _, exists := seen[s]; exists {
			t.Error("GenerateRandomString() produced duplicate value")
		}
		seen[s] = struct{}{}
	}
}
