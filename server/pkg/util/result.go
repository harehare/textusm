package util

import "github.com/samber/mo"

func ResultToTuple[T any](r mo.Result[T]) (T, error) {
	return r.OrEmpty(), r.Error()
}
