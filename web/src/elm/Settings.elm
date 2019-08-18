module Settings exposing (settingsDecoder)

import Json.Decode as D
import Models.Diagram as Diagram exposing (Color, ColorSettings, Settings, Size)
import Models.Model as Model


settingsDecoder : D.Decoder Model.Settings
settingsDecoder =
    D.map8 Model.Settings
        (D.maybe (D.field "position" D.int))
        (D.field "font" D.string)
        (D.maybe (D.field "diagramId" D.string))
        (D.field "storyMap" diagramDecoder)
        (D.maybe (D.field "text" D.string))
        (D.maybe (D.field "title" D.string))
        (D.maybe (D.field "miniMap" D.bool))
        (D.maybe (D.field "github" githubDecoder))


githubDecoder : D.Decoder Model.GithubSettings
githubDecoder =
    D.map2 Model.GithubSettings
        (D.field "owner" D.string)
        (D.field "repo" D.string)


diagramDecoder : D.Decoder Diagram.Settings
diagramDecoder =
    D.map4 Diagram.Settings
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
