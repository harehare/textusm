package model

import "firebase.google.com/go/auth"

type User struct {
	UID   string
	Name  string
	Email string
}

func NewUser(u *auth.UserRecord) User {
	return User{
		UID:   u.UID,
		Name:  u.DisplayName,
		Email: u.Email,
	}
}
