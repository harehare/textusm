package scalar

import (
	"github.com/99designs/gqlgen/graphql"
	"github.com/harehare/textusm/pkg/domain/values"
)

func MarshalItemID(i *values.ItemID) graphql.Marshaler {
	return graphql.MarshalString(i.String())
}

func UnmarshalItemID(v interface{}) (*values.ItemID, error) {
	v2, err := graphql.UnmarshalString(v)
	if err != nil {
		return nil, err
	}
	itemID := values.NewItemID(v2)
	return &itemID, nil
}
