package model

import (
	"net"
	"strings"

	"golang.org/x/crypto/bcrypt"
)

type Share struct {
	Token          *string
	Password       *string
	AllowIPList    []string
	ExpireTime     *int64
	AllowEmailList []string
}

func (s *Share) ComparePassword(password string) error {
	return bcrypt.CompareHashAndPassword([]byte(*s.Password), []byte(password))
}

func (s *Share) CheckEmail(email string) bool {
	if len(s.AllowEmailList) == 0 {
		return true
	}

	for _, e := range s.AllowEmailList {
		if e == email {
			return true
		}
	}

	return false
}

func (s *Share) CheckIPWithinRange(remoteIP string) bool {
	if len(s.AllowIPList) == 0 {
		return true
	}

	for _, ip := range s.AllowIPList {
		if remoteIP == ip {
			return true
		}
		if !strings.Contains(ip, "/") {
			continue
		}

		_, subnet, err := net.ParseCIDR(ip)

		if err != nil {
			continue
		}

		parsedIP := net.ParseIP(ip)

		if parsedIP == nil {
			continue
		}

		if subnet.Contains(parsedIP) {
			return true
		}
	}
	return false
}
