package graphql

import (
	"context"
	"time"

	"cloud.google.com/go/firestore"
	"github.com/harehare/textusm/pkg/context/values"
	itemModel "github.com/harehare/textusm/pkg/domain/model/item"
	settingsModel "github.com/harehare/textusm/pkg/domain/model/settings"
	v "github.com/harehare/textusm/pkg/domain/values"
)

func (r *Resolver) Mutation() MutationResolver { return &mutationResolver{r} }

type mutationResolver struct{ *Resolver }

func (r *mutationResolver) Save(ctx context.Context, input InputItem, isPublic *bool) (*itemModel.DiagramItem, error) {
	currentTime := time.Now()
	if input.ID == nil {
		saveItem, err := itemModel.NewDiagramItem().WithID("").WithTitle(input.Title).WithPlainText(input.Text).WithThumbnail(input.Thumbnail).
			WithDiagram(*input.Diagram).WithIsPublic(input.IsPublic).WithIsBookmark(input.IsBookmark).WithCreatedAt(currentTime).WithUpdatedAt(currentTime).Build()

		if err != nil {
			return nil, err
		}

		return r.service.Save(ctx, saveItem, *isPublic)
	}
	baseItem, err := r.service.FindByID(ctx, *input.ID, false)

	if err != nil {
		return nil, err
	}

	saveItem, err := itemModel.NewDiagramItem().WithID(baseItem.ID()).WithTitle(input.Title).WithPlainText(input.Text).WithThumbnail(input.Thumbnail).
		WithDiagram(*input.Diagram).WithIsPublic(input.IsPublic).WithIsBookmark(input.IsBookmark).WithCreatedAt(baseItem.CreatedAt()).WithUpdatedAt(currentTime).Build()

	if err != nil {
		return nil, err
	}

	return r.service.Save(ctx, saveItem, *isPublic)
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

func (r *mutationResolver) Bookmark(ctx context.Context, itemID string, isBookmark bool) (*itemModel.DiagramItem, error) {
	return r.service.Bookmark(ctx, itemID, isBookmark)
}

func (r *mutationResolver) Share(ctx context.Context, input InputShareItem) (string, error) {
	var p string
	if input.Password == nil {
		p = ""
	} else {
		p = *input.Password
	}
	jwtToken, err := r.service.Share(ctx, input.ItemID, *input.ExpSecond, p, input.AllowIPList, input.AllowEmailList)
	return *jwtToken, err
}

func (r *mutationResolver) SaveGist(ctx context.Context, input InputGistItem) (*itemModel.GistItem, error) {
	gist := itemModel.GistItem{
		ID:         *input.ID,
		Title:      input.Title,
		Thumbnail:  input.Thumbnail,
		Diagram:    *input.Diagram,
		IsBookmark: input.IsBookmark,
		CreatedAt:  time.Now(),
		UpdatedAt:  time.Now(),
	}
	return r.gistService.Save(ctx, &gist)
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
	}
	return r.settingsService.Save(ctx, *diagram, &settings)
}

func inputColorToColor(input InputColor) settingsModel.Color {
	return settingsModel.Color{
		ForegroundColor: input.ForegroundColor,
		BackgroundColor: input.BackgroundColor,
	}
}
