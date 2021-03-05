package error

import "fmt"

type Code string

const (
	NotFound        Code = "NotFound"
	NoAuthorization Code = "NoAuthorization"
	UnKnown         Code = "UnKnown"
)

type RepositoryError struct {
	code Code
	err  error
}

type ServiceError struct {
	code Code
	err  error
}

func (e RepositoryError) Error() string {
	return fmt.Sprintf("RepositoryError: %s", e.code)
}

func (e ServiceError) Error() string {
	return fmt.Sprintf("ServiceError: %s", e.code)
}

func NotFoundError(err error) RepositoryError {
	return RepositoryError{code: NotFound, err: err}
}

func UnKnownError(err error) RepositoryError {
	return RepositoryError{code: UnKnown, err: err}
}

func NoAuthorizationError(err error) ServiceError {
	return ServiceError{code: NoAuthorization, err: err}
}

func GetCode(err error) Code {
	_, isRepoError := err.(*RepositoryError)
	_, isServiceError := err.(*ServiceError)

	if !isRepoError && !isServiceError {
		return UnKnown
	}

	if isRepoError {
		return err.(*RepositoryError).code
	}

	if isServiceError {
		return err.(*ServiceError).code
	}

	return UnKnown
}

func (e *RepositoryError) Unwrap() error {
	return e.err
}

func (e *ServiceError) Unwrap() error {
	return e.err
}
