package graphql

import (
	"context"

	"github.com/99designs/gqlgen/graphql"
	itemModel "github.com/harehare/textusm/pkg/domain/model/item"
	"github.com/harehare/textusm/pkg/domain/model/settings"
	shareModel "github.com/harehare/textusm/pkg/domain/model/share"
	"github.com/harehare/textusm/pkg/domain/values"
	"github.com/harehare/textusm/pkg/presentation/graphql/union"
)

func getPreloads(ctx context.Context) map[string]struct{} {
	return getNestedPreloads(
		graphql.GetOperationContext(ctx),
		graphql.CollectFieldsCtx(ctx, nil),
		"",
	)
}

func getNestedPreloads(ctx *graphql.OperationContext, fields []graphql.CollectedField, prefix string) map[string]struct{} {
	preloads := make(map[string]struct{})
	for _, column := range fields {
		prefixColumn := getPreloadString(prefix, column.Name)
		preloads[prefixColumn] = struct{}{}
		for k := range getNestedPreloads(ctx, graphql.CollectFields(ctx, column.Selections, nil), prefixColumn) {
			preloads[k] = struct{}{}
		}
	}
	return preloads
}

func getPreloadString(prefix, name string) string {
	if len(prefix) > 0 {
		return prefix + "." + name
	}
	return name
}

func (r *Resolver) Query() QueryResolver { return &queryResolver{r} }

type queryResolver struct{ *Resolver }

func (r *queryResolver) Item(ctx context.Context, id string, isPublic *bool) (*itemModel.Item, error) {
	return r.service.FindByID(ctx, id, *isPublic)
}

func (r *queryResolver) Items(ctx context.Context, offset *int, limit *int, isBookmark *bool, isPublic *bool) ([]*itemModel.Item, error) {
	return r.service.Find(ctx, *offset, *limit, *isPublic, *isBookmark, getPreloads(ctx))
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

func (r *queryResolver) ShareCondition(ctx context.Context, itemID string) (*shareModel.ShareCondition, error) {
	return r.service.FindShareCondition(ctx, itemID)
}

func (r *queryResolver) AllItems(ctx context.Context, offset, limit *int) ([]union.DiagramItem, error) {
	var diagramItems []union.DiagramItem
	items, err := r.service.Find(ctx, *offset, *limit, false, false, getPreloads(ctx))

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

func (r *queryResolver) GistItem(ctx context.Context, id string) (*itemModel.GistItem, error) {
	return r.gistService.FindByID(ctx, id)
}

func (r *queryResolver) GistItems(ctx context.Context, offset, limit *int) ([]*itemModel.GistItem, error) {
	return r.gistService.Find(ctx, *offset, *limit)
}

func (r *queryResolver) Settings(ctx context.Context, diagram *values.Diagram) (*settings.Settings, error) {
	return r.settingsService.Find(ctx, *diagram)
}
