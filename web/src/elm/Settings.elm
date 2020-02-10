module Settings exposing (settingsDecoder)

import Json.Decode as D
import Models.Diagram as Diagram exposing (Color, ColorSettings, Settings, Size)
import Models.Settings as Settings exposing (EditorSettings)


settingsDecoder : D.Decoder Settings.Settings
settingsDecoder =
    D.map7 Settings.Settings
        (D.maybe (D.field "position" D.int))
        (D.field "font" D.string)
        (D.maybe (D.field "diagramId" D.string))
        (D.field "storyMap" diagramDecoder)
        (D.maybe (D.field "text" D.string))
        (D.maybe (D.field "title" D.string))
        (D.maybe (D.field "editor" editorSettingsDecoder))


diagramDecoder : D.Decoder Diagram.Settings
diagramDecoder =
    D.map5 Diagram.Settings
        (D.field "font" D.string)
        (D.field "size" sizeDecoder)
        (D.field "color" colorSettingsDecoder)
        (D.field "backgroundColor" D.string)
        (D.maybe (D.field "zoomControl" D.bool))


editorSettingsDecoder : D.Decoder EditorSettings
editorSettingsDecoder =
    D.map3 EditorSettings
        (D.field "fontSize" D.int)
        (D.field "wordWrap" D.bool)
        (D.field "showLineNumber" D.bool)


colorSettingsDecoder : D.Decoder ColorSettings
colorSettingsDecoder =
    D.map6 ColorSettings
        (D.field "activity" colorDecoder)
        (D.field "task" colorDecoder)
        (D.field "story" colorDecoder)
        (D.field "line" D.string)
        (D.field "label" D.string)
        (D.maybe (D.field "text" D.string))


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
