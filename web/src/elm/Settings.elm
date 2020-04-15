module Settings exposing (settingsDecoder, settingsEncoder)

import GraphQL.Models.DiagramItem as DiagramItem
import Json.Decode as D
import Json.Encode as E
import Json.Encode.Extra exposing (maybe)
import Models.Diagram as Diagram exposing (Color, ColorSettings, Settings, Size)
import Models.Settings as Settings exposing (EditorSettings)


settingsDecoder : D.Decoder Settings.Settings
settingsDecoder =
    D.map8 Settings.Settings
        (D.maybe (D.field "position" D.int))
        (D.field "font" D.string)
        (D.maybe (D.field "diagramId" D.string))
        (D.field "storyMap" diagramDecoder)
        (D.maybe (D.field "text" D.string))
        (D.maybe (D.field "title" D.string))
        (D.maybe (D.field "editor" editorSettingsDecoder))
        (D.maybe (D.field "diagram" DiagramItem.decoder))


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


settingsEncoder : Settings.Settings -> E.Value
settingsEncoder settings =
    E.object
        [ ( "position", maybe E.int settings.position )
        , ( "font", E.string settings.font )
        , ( "diagramId", maybe E.string settings.diagramId )
        , ( "storyMap", diagramEncoder settings.storyMap )
        , ( "text", maybe E.string settings.text )
        , ( "title", maybe E.string settings.title )
        , ( "editor", maybe editorSettingsEncoder settings.editor )
        , ( "diagram", maybe DiagramItem.encoder settings.diagram )
        ]


diagramEncoder : Diagram.Settings -> E.Value
diagramEncoder settings =
    E.object
        [ ( "font", E.string settings.font )
        , ( "size", sizeEncoder settings.size )
        , ( "color", colorSettingsEncoder settings.color )
        , ( "backgroundColor", E.string settings.backgroundColor )
        , ( "zoomControl", maybe E.bool settings.zoomControl )
        ]


editorSettingsEncoder : EditorSettings -> E.Value
editorSettingsEncoder editorSettings =
    E.object
        [ ( "fontSize", E.int editorSettings.fontSize )
        , ( "wordWrap", E.bool editorSettings.wordWrap )
        , ( "showLineNumber", E.bool editorSettings.showLineNumber )
        ]


colorSettingsEncoder : ColorSettings -> E.Value
colorSettingsEncoder colorSettings =
    E.object
        [ ( "activity", colorEncoder colorSettings.activity )
        , ( "task", colorEncoder colorSettings.task )
        , ( "story", colorEncoder colorSettings.story )
        , ( "line", E.string colorSettings.line )
        , ( "label", E.string colorSettings.label )
        , ( "text", maybe E.string colorSettings.text )
        ]


colorEncoder : Color -> E.Value
colorEncoder color =
    E.object
        [ ( "color", E.string color.color )
        , ( "backgroundColor", E.string color.backgroundColor )
        ]


sizeEncoder : Size -> E.Value
sizeEncoder size =
    E.object
        [ ( "width", E.int size.width )
        , ( "height", E.int size.height )
        ]
