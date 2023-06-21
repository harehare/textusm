package share

import (
	"net"
	"strings"

	"golang.org/x/crypto/bcrypt"
)

type Share struct {
	Token          string
	Password       string
	AllowIPList    []string
	ExpireTime     int64
	AllowEmailList []string
}

type ShareCondition struct {
	Token          string   `json:"token"`
	UsePassword    bool     `json:"usePassword"`
	ExpireTime     int      `json:"expireTime"`
	AllowIPList    []string `json:"allowIPList"`
	AllowEmailList []string `json:"allowEmailList"`
}

func (s *Share) ComparePassword(password string) error {
	return bcrypt.CompareHashAndPassword([]byte(s.Password), []byte(password))
}

func (s *Share) ValidEmail(email string) bool {
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

func (s *Share) CheckIpWithinRange(remoteIP string) bool {
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

		parsedIP := net.ParseIP(remoteIP)

		if parsedIP == nil {
			continue
		}

		if subnet.Contains(parsedIP) {
			return true
		}
	}
	return false
}
