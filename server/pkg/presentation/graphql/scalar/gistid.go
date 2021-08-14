package scalar

import (
	"github.com/99designs/gqlgen/graphql"
	"github.com/harehare/textusm/pkg/domain/values"
)

func MarshalGistID(i *values.GistID) graphql.Marshaler {
	return graphql.MarshalString(i.String())
}

func UnmarshalGistID(v interface{}) (*values.GistID, error) {
	v2, err := graphql.UnmarshalString(v)
	if err != nil {
		return nil, err
	}
	gistID := values.NewGistID(v2)
	return &gistID, nil
}
