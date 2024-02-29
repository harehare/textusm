package share

import (
	"strings"
	"testing"
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
