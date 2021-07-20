package server

import (
	"context"

	itemModel "github.com/harehare/textusm/pkg/domain/model/item"
	shareModel "github.com/harehare/textusm/pkg/domain/model/share"
	v "github.com/harehare/textusm/pkg/domain/values"
)

func (r *Resolver) Query() QueryResolver { return &queryResolver{r} }

type queryResolver struct{ *Resolver }

func (r *queryResolver) Item(ctx context.Context, id *v.ItemID, isPublic *bool) (*itemModel.Item, error) {
	return r.service.FindDiagram(ctx, *id, *isPublic)
}

func (r *queryResolver) Items(ctx context.Context, offset *int, limit *int, isBookmark *bool, isPublic *bool) ([]*itemModel.Item, error) {
	return r.service.FindDiagrams(ctx, *offset, *limit, *isPublic)
}

func (r *queryResolver) ShareItem(ctx context.Context, token string, password *string) (*itemModel.Item, error) {
	var p string
	if password == nil {
		p = ""
	} else {
		p = *password
	}
	return r.service.FindShareItem(ctx, token, p)
}

func (r *queryResolver) ShareCondition(ctx context.Context, itemID *v.ItemID) (*shareModel.ShareCondition, error) {
	return r.service.FindShareCondition(ctx, *itemID)
}

func (r *queryResolver) GistItem(ctx context.Context, id *v.GistID) (*itemModel.GistItem, error) {
	panic("not implemented")
}

func (r *queryResolver) GistItems(ctx context.Context, offset, limit *int) ([]*itemModel.GistItem, error) {
	panic("not implemented")
}
