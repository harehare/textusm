package util

import "github.com/samber/mo"

func ToOption[T any, U *T](v U) mo.Option[T] {
	if v == nil {
		return mo.None[T]()
	}

	return mo.Some(*v)
}

func OptionToString(v mo.Option[string]) *string {
	s := v.OrElse("")

	if s == "" {
		return nil
	}

	return &s
}
