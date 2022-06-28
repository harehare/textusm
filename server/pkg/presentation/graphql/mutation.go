package graphql

import (
	"context"
	"time"

	"cloud.google.com/go/firestore"
	"github.com/harehare/textusm/pkg/context/values"
	"github.com/harehare/textusm/pkg/domain/model/item/diagramitem"
	"github.com/harehare/textusm/pkg/domain/model/item/gistitem"
	settingsModel "github.com/harehare/textusm/pkg/domain/model/settings"
	v "github.com/harehare/textusm/pkg/domain/values"
	"github.com/harehare/textusm/pkg/util"
)

func (r *Resolver) Mutation() MutationResolver { return &mutationResolver{r} }

type mutationResolver struct{ *Resolver }

func (r *mutationResolver) Save(ctx context.Context, input InputItem, isPublic *bool) (*diagramitem.DiagramItem, error) {
	currentTime := time.Now()
	if input.ID == nil {
		saveItem := diagramitem.New().WithID("").WithTitle(input.Title).WithPlainText(input.Text).WithThumbnail(util.ToOption(input.Thumbnail)).
			WithDiagram(*input.Diagram).WithIsPublic(input.IsPublic).WithIsBookmark(input.IsBookmark).WithCreatedAt(currentTime).WithUpdatedAt(currentTime).Build()

		if saveItem.IsError() {
			return nil, saveItem.Error()
		}

		return util.ResultToTuple(r.service.Save(ctx, saveItem.OrEmpty(), *isPublic))
	}
	baseItem := r.service.FindByID(ctx, *input.ID, false)

	if baseItem.IsError() {
		return nil, baseItem.Error()
	}

	saveItem := diagramitem.New().WithID(baseItem.OrEmpty().ID()).WithTitle(input.Title).WithPlainText(input.Text).WithThumbnail(util.ToOption(input.Thumbnail)).
		WithDiagram(*input.Diagram).WithIsPublic(input.IsPublic).WithIsBookmark(input.IsBookmark).WithCreatedAt(baseItem.OrEmpty().CreatedAt()).WithUpdatedAt(currentTime).Build()

	if saveItem.IsError() {
		return nil, saveItem.Error()
	}

	return util.ResultToTuple(r.service.Save(ctx, saveItem.OrEmpty(), *isPublic))
}

func (r *mutationResolver) Delete(ctx context.Context, itemID string, isPublic *bool) (string, error) {
	err := r.client.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
		ctx = values.WithTx(ctx, tx)
		return r.service.Delete(ctx, itemID, *isPublic)
	})

	if err != nil {
		return "", err
	}

	return itemID, nil
}

func (r *mutationResolver) Bookmark(ctx context.Context, itemID string, isBookmark bool) (*diagramitem.DiagramItem, error) {
	return util.ResultToTuple(r.service.Bookmark(ctx, itemID, isBookmark))
}

func (r *mutationResolver) Share(ctx context.Context, input InputShareItem) (string, error) {
	var p string
	if input.Password == nil {
		p = ""
	} else {
		p = *input.Password
	}
	return util.ResultToTuple(r.service.Share(ctx, input.ItemID, *input.ExpSecond, p, input.AllowIPList, input.AllowEmailList))
}

func (r *mutationResolver) SaveGist(ctx context.Context, input InputGistItem) (*gistitem.GistItem, error) {
	currentTime := time.Now()
	gist := gistitem.New().
		WithID(*input.ID).
		WithURL(input.URL).
		WithTitle(input.Title).
		WithThumbnail(util.ToOption(input.Thumbnail)).
		WithDiagram(*input.Diagram).
		WithIsBookmark(input.IsBookmark).
		WithCreatedAt(currentTime).
		WithUpdatedAt(currentTime).
		Build()

	if gist.IsError() {
		return nil, gist.Error()
	}

	return util.ResultToTuple(r.gistService.Save(ctx, gist.OrEmpty()))
}

func (r *mutationResolver) DeleteGist(ctx context.Context, gistID string) (string, error) {
	err := r.gistService.Delete(ctx, gistID)
	return gistID, err
}

func (r *mutationResolver) SaveSettings(ctx context.Context, diagram *v.Diagram, input InputSettings) (*settingsModel.Settings, error) {
	settings := settingsModel.Settings{
		Font:            input.Font,
		Width:           input.Width,
		Height:          input.Height,
		BackgroundColor: input.BackgroundColor,
		ActivityColor:   inputColorToColor(*input.ActivityColor),
		TaskColor:       inputColorToColor(*input.TaskColor),
		StoryColor:      inputColorToColor(*input.StoryColor),
		LineColor:       input.LineColor,
		LabelColor:      input.LabelColor,
		TextColor:       input.TextColor,
		ZoomControl:     input.ZoomControl,
		Scale:           input.Scale,
		Toolbar:         input.Toolbar,
	}
	return util.ResultToTuple(r.settingsService.Save(ctx, *diagram, &settings))
}

func inputColorToColor(input InputColor) settingsModel.Color {
	return settingsModel.Color{
		ForegroundColor: input.ForegroundColor,
		BackgroundColor: input.BackgroundColor,
	}
}
