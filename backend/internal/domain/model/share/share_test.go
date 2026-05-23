package share

import (
	"strings"
	"testing"

	"golang.org/x/crypto/bcrypt"
)

func TestValidEmail(t *testing.T) {
	tests := []struct {
		allowEmailList []string
		email          string
		want           bool
	}{
		{
			[]string{},
			"",
			true,
		},
		{
			[]string{"test@gmail.com"},
			"test@gmail.com",
			true,
		},
		{
			[]string{"test+2@gmail.com"},
			"test@gmail.com",
			false,
		},
	}
	for _, tt := range tests {
		t.Run("ValidEmail("+strings.Join(tt.allowEmailList, ", ")+", "+tt.email+")", func(t *testing.T) {
			share := Share{
				Token:          "",
				Password:       "",
				AllowIPList:    []string{},
				ExpireTime:     0,
				AllowEmailList: tt.allowEmailList,
			}

			if got := share.ValidEmail(tt.email); got != tt.want {
				t.Errorf("ValidEmail("+tt.email+") = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestCheckIpWithinRange(t *testing.T) {
	tests := []struct {
		allowIPList []string
		remoteIP    string
		want        bool
	}{
		{
			[]string{},
			"",
			true,
		},
		{
			[]string{},
			"192.168.0.1",
			true,
		},
		{
			[]string{"192.168.0.1"},
			"192.168.0.1",
			true,
		},
		{
			[]string{"192.168.0.0/24"},
			"192.168.0.1",
			true,
		},
		{
			[]string{"192.168.0.0/24"},
			"192.168.0.254",
			true,
		},
		{
			[]string{"192.168.0.2"},
			"192.168.0.1",
			false,
		},
	}
	for _, tt := range tests {
		t.Run("CheckIpWithinRange("+strings.Join(tt.allowIPList, ", ")+", "+tt.remoteIP+")", func(t *testing.T) {
			share := Share{
				Token:          "",
				Password:       "",
				AllowIPList:    tt.allowIPList,
				ExpireTime:     0,
				AllowEmailList: []string{},
			}

			if got := share.CheckIpWithinRange(tt.remoteIP); got != tt.want {
				t.Errorf("CheckIpWithinRange("+tt.remoteIP+") = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestComparePasswordMatch(t *testing.T) {
	password := "secret123"
	hashed, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.MinCost)
	if err != nil {
		t.Fatalf("bcrypt error: %v", err)
	}

	share := Share{Password: string(hashed)}
	if err := share.ComparePassword(password); err != nil {
		t.Errorf("ComparePassword() with correct password should return nil, got %v", err)
	}
}

func TestComparePasswordMismatch(t *testing.T) {
	hashed, _ := bcrypt.GenerateFromPassword([]byte("correct"), bcrypt.MinCost)
	share := Share{Password: string(hashed)}

	if err := share.ComparePassword("wrong"); err == nil {
		t.Error("ComparePassword() with wrong password should return error")
	}
}

func TestValidEmailMultipleAllowed(t *testing.T) {
	share := Share{
		AllowEmailList: []string{"a@example.com", "b@example.com"},
	}
	if !share.ValidEmail("a@example.com") {
		t.Error("ValidEmail() should allow first email in list")
	}
	if !share.ValidEmail("b@example.com") {
		t.Error("ValidEmail() should allow second email in list")
	}
	if share.ValidEmail("c@example.com") {
		t.Error("ValidEmail() should deny email not in list")
	}
}

func TestCheckIpCIDRBoundary(t *testing.T) {
	share := Share{AllowIPList: []string{"10.0.0.0/8"}}
	if !share.CheckIpWithinRange("10.255.255.255") {
		t.Error("CheckIpWithinRange() should allow last IP in /8 CIDR")
	}
	if share.CheckIpWithinRange("11.0.0.0") {
		t.Error("CheckIpWithinRange() should deny IP outside /8 CIDR")
	}
}
