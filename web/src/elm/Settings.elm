module Settings exposing (settingsDecoder)

import Json.Decode as D
import Models.Figure as Figure exposing (Color, ColorSettings, Settings, Size)
import Models.Model as Model exposing (GithubSettings, Settings)


settingsDecoder : D.Decoder Model.Settings
settingsDecoder =
    D.map6 Model.Settings
        (D.maybe (D.field "position" D.int))
        (D.field "font" D.string)
        (D.field "storyMap" figureDecoder)
        (D.maybe (D.field "text" D.string))
        (D.maybe (D.field "title" D.string))
        (D.maybe (D.field "github" githubDecoder))


githubDecoder : D.Decoder GithubSettings
githubDecoder =
    D.map3 GithubSettings
        (D.field "owner" D.string)
        (D.field "repo" D.string)
        (D.field "token" D.string)


figureDecoder : D.Decoder Figure.Settings
figureDecoder =
    D.map4 Figure.Settings
        (D.field "font" D.string)
        (D.field "size" sizeDecoder)
        (D.field "color" colorSettingsDecoder)
        (D.field "backgroundColor" D.string)


colorSettingsDecoder : D.Decoder ColorSettings
colorSettingsDecoder =
    D.map6 ColorSettings
        (D.field "activity" colorDecoder)
        (D.field "task" colorDecoder)
        (D.field "story" colorDecoder)
        (D.field "comment" colorDecoder)
        (D.field "line" D.string)
        (D.field "label" D.string)


colorDecoder : D.Decoder Color
colorDecoder =
    D.map2 Color
        (D.field "color" D.string)
        (D.field "backgroundColor" D.string)


sizeDecoder : D.Decoder Size
sizeDecoder =
    D.map2 Size
        (D.field "width" D.int)
        (D.field "height" D.int)
