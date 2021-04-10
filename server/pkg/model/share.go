package model

import "golang.org/x/crypto/bcrypt"

type ShareInfo struct {
	Password    *string
	AllowIPList []string
}

func (s *ShareInfo) ComparePassword(password string) error {
	return bcrypt.CompareHashAndPassword([]byte(*s.Password), []byte(password))
}
