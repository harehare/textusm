package sqlite

import (
	"database/sql"
	"time"
)

const (
	LocationSYSTEM = "system"
	LocationGIST   = "gist"
)

func StringToNullString(s *string) sql.NullString {
	if s == nil {
		return sql.NullString{String: "", Valid: false}
	} else {
		return sql.NullString{String: *s, Valid: true}
	}
}

func NullStringToString(s sql.NullString) *string {
	if s.Valid {
		return &s.String
	} else {
		return nil
	}
}

func NullIntToBool(s sql.NullInt64) *bool {
	if s.Valid && s.Int64 == 1 {
		val := true
		return &val
	} else {
		return nil
	}
}

func BoolToNullInt(b *bool) sql.NullInt64 {
	if b != nil && *b {
		return sql.NullInt64{Int64: 1, Valid: true}
	} else {
		return sql.NullInt64{Int64: 0, Valid: false}
	}
}

func IntToBool(i int64) bool {
	return i == 1
}

func BoolToInt(b bool) int64 {
	if b {
		return 1
	} else {
		return 0
	}
}

func IntToDateTime(i int64) time.Time {
	return time.Unix(i, 0)
}

func DateTimeToInt(t time.Time) int64 {
	return t.Unix()
}
