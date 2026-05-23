package error

import (
	"errors"
	"fmt"
	"strings"
	"testing"
)

func TestErrorMessages(t *testing.T) {
	baseErr := errors.New("underlying error")

	tests := []struct {
		name        string
		err         error
		wantContain string
	}{
		{"NotFoundError", NotFoundError(baseErr), "NotFound"},
		{"UnKnownError", UnKnownError(baseErr), "UnKnown"},
		{"ForbiddenError", ForbiddenError(baseErr), "Forbidden"},
		{"URLExpiredError", URLExpiredError(baseErr), "URLExpired"},
		{"NoAuthorizationError", NoAuthorizationError(baseErr), "NoAuthorization"},
		{"DecryptionFailedError", DecryptionFailedError(baseErr), "DecryptionFailed"},
		{"EncryptionFailedError", EncryptionFailedError(baseErr), "EncryptionFailed"},
		{"InvalidParameterError", InvalidParameterError(baseErr), "InvalidParameter"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			msg := tt.err.Error()
			if !strings.Contains(msg, tt.wantContain) {
				t.Errorf("error message %q does not contain %q", msg, tt.wantContain)
			}
		})
	}
}

func TestGetCode(t *testing.T) {
	baseErr := errors.New("base")

	tests := []struct {
		name string
		err  error
		want Code
	}{
		{"NotFoundError", NotFoundError(baseErr), NotFound},
		{"UnKnownError", UnKnownError(baseErr), UnKnown},
		{"ForbiddenError", ForbiddenError(baseErr), Forbidden},
		{"URLExpiredError", URLExpiredError(baseErr), URLExpired},
		{"NoAuthorizationError", NoAuthorizationError(baseErr), NoAuthorization},
		{"DecryptionFailedError", DecryptionFailedError(baseErr), DecryptionFailed},
		{"EncryptionFailedError", EncryptionFailedError(baseErr), EncryptionFailed},
		{"InvalidParameterError", InvalidParameterError(baseErr), InvalidParameter},
		{"unknown error type", baseErr, UnKnown},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := GetCode(tt.err)
			if got != tt.want {
				t.Errorf("GetCode() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestGetCodeWrapped(t *testing.T) {
	baseErr := errors.New("base")

	wrapped := fmt.Errorf("wrapped: %w", NotFoundError(baseErr))
	if got := GetCode(wrapped); got != NotFound {
		t.Errorf("GetCode(wrapped RepositoryError) = %v, want NotFound", got)
	}

	wrapped = fmt.Errorf("wrapped: %w", ForbiddenError(baseErr))
	if got := GetCode(wrapped); got != Forbidden {
		t.Errorf("GetCode(wrapped ServiceError) = %v, want Forbidden", got)
	}

	wrapped = fmt.Errorf("wrapped: %w", InvalidParameterError(baseErr))
	if got := GetCode(wrapped); got != InvalidParameter {
		t.Errorf("GetCode(wrapped DomainError) = %v, want InvalidParameter", got)
	}
}

func TestUnwrap(t *testing.T) {
	baseErr := errors.New("original")

	repoErr := NotFoundError(baseErr)
	if !errors.Is(&repoErr, baseErr) {
		t.Error("RepositoryError.Unwrap() should allow errors.Is to find underlying error")
	}

	svcErr := ForbiddenError(baseErr)
	if !errors.Is(&svcErr, baseErr) {
		t.Error("ServiceError.Unwrap() should allow errors.Is to find underlying error")
	}

	domErr := InvalidParameterError(baseErr)
	if !errors.Is(&domErr, baseErr) {
		t.Error("DomainError.Unwrap() should allow errors.Is to find underlying error")
	}
}

func TestSentinelErrors(t *testing.T) {
	sentinels := []error{
		ErrInvalidId,
		ErrInvalidTitle,
		ErrInvalidDiagram,
		ErrInvalidIsPublic,
		ErrInvalidIsBookmark,
		ErrInvalidCreatedAt,
		ErrInvalidUpdatedAt,
		ErrInvalidURL,
		ErrNotAuthorization,
		ErrNotAllowIpAddress,
		ErrSignInRequired,
		ErrNotAllowEmail,
		ErrPasswordIsRequired,
		ErrNotDiagramOwner,
		ErrUnpadError,
		ErrBlockSizeError,
	}

	for _, err := range sentinels {
		if err == nil {
			t.Error("sentinel error should not be nil")
		}
		if err.Error() == "" {
			t.Errorf("sentinel error %T should have non-empty message", err)
		}
	}
}
