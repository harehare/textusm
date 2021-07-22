package graphql

import (
	"context"

	itemModel "github.com/harehare/textusm/pkg/domain/model/item"
	shareModel "github.com/harehare/textusm/pkg/domain/model/share"
	v "github.com/harehare/textusm/pkg/domain/values"
	"github.com/harehare/textusm/pkg/presentation/graphql/union"
)

func (r *Resolver) Query() QueryResolver { return &queryResolver{r} }

type queryResolver struct{ *Resolver }

func (r *queryResolver) Item(ctx context.Context, id *v.ItemID, isPublic *bool) (*itemModel.Item, error) {
	return r.service.FindByID(ctx, *id, *isPublic)
}

func (r *queryResolver) Items(ctx context.Context, offset *int, limit *int, isBookmark *bool, isPublic *bool) ([]*itemModel.Item, error) {
	return r.service.Find(ctx, *offset, *limit, *isPublic)
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

func (r *queryResolver) AllItems(ctx context.Context, offset, limit *int) ([]union.DiagramItem, error) {
	var diagramItems []union.DiagramItem
	items, err := r.service.Find(ctx, *offset, *limit, false)

	if err != nil {
		return nil, err
	}

	gistItems, err := r.gistService.Find(ctx, *offset, *limit)

	if err != nil {
		return nil, err
	}

	for _, item := range items {
		diagramItems = append(diagramItems, item)
	}

	for _, item := range gistItems {
		diagramItems = append(diagramItems, item)
	}

	return diagramItems, nil
}

func (r *queryResolver) GistItem(ctx context.Context, id *v.GistID) (*itemModel.GistItem, error) {
	return r.gistService.FindByID(ctx, *id)
}

func (r *queryResolver) GistItems(ctx context.Context, offset, limit *int) ([]*itemModel.GistItem, error) {
	return r.gistService.Find(ctx, *offset, *limit)
}
