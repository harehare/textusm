module Models.Settings exposing
    ( EditorSettings
    , Settings
    , activityBackgroundColor
    , activityColor
    , backgroundColor
    , decoder
    , defaultEditorSettings
    , defaultSettings
    , encoder
    , exportEncoder
    , font
    , fontSize
    , height
    , importDecoder
    , labelColor
    , legacyEncoder
    , lineColor
    , ofDiagramSettings
    , showLineNumber
    , storyBackgroundColor
    , storyColor
    , taskBackgroundColor
    , taskColor
    , textColor
    , toolbar
    , width
    , wordWrap
    , zoomControl
    )

import Json.Decode as D
import Json.Decode.Pipeline exposing (custom, hardcoded, optional, required)
import Json.Encode as E
import Json.Encode.Extra exposing (maybe)
import Models.Color as Color exposing (Color)
import Models.Diagram.CardSize as CardSize exposing (CardSize)
import Models.Diagram.Id as DiagramId exposing (DiagramId)
import Models.Diagram.Item as DiagramItem exposing (DiagramItem)
import Models.Diagram.Location as DiagramLocation exposing (Location)
import Models.Diagram.Scale as Scale
import Models.Diagram.Settings as DiagramSettings
import Models.Text as Text exposing (Text)
import Models.Theme as Theme exposing (Theme)
import Models.Title as Title exposing (Title)
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Monocle.Optional exposing (Optional)


type alias EditorSettings =
    { fontSize : Int
    , wordWrap : Bool
    , showLineNumber : Bool
    }


type alias Settings =
    { position : Maybe Int
    , font : String
    , diagramId : Maybe DiagramId
    , diagramSettings : DiagramSettings.Settings
    , text : Maybe Text
    , title : Maybe Title
    , editor : Maybe EditorSettings
    , diagram : Maybe DiagramItem
    , location : Maybe Location
    , theme : Maybe Theme
    }


defaultEditorSettings : Maybe EditorSettings -> EditorSettings
defaultEditorSettings settings =
    Maybe.withDefault
        { fontSize = 14
        , wordWrap = False
        , showLineNumber = True
        }
        settings


defaultSettings : Theme -> Settings
defaultSettings theme =
    { position = Just -10
    , font = "Nunito Sans"
    , diagramId = Nothing
    , diagramSettings =
        { font = "Nunito Sans"
        , size = { width = CardSize.fromInt 140, height = CardSize.fromInt 65 }
        , color =
            { activity =
                { color = Color.white
                , backgroundColor = Color.background1Defalut
                }
            , task =
                { color = Color.white
                , backgroundColor = Color.background2Defalut
                }
            , story =
                { color = Color.gray
                , backgroundColor = Color.white
                }
            , line = Color.lineDefalut
            , label = Color.labelDefalut
            , text = Just <| Color.textDefalut
            }
        , backgroundColor =
            case theme of
                Theme.System True ->
                    Color.backgroundDarkDefalut

                Theme.System False ->
                    Color.backgroundDefalut

                Theme.Dark ->
                    Color.backgroundDarkDefalut

                Theme.Light ->
                    Color.backgroundDefalut
        , zoomControl = Just True
        , scale = Just Scale.default
        , toolbar = Nothing
        , lockEditing = Nothing
        }
    , text = Nothing
    , title = Nothing
    , editor = Nothing
    , diagram = Nothing
    , location = Nothing
    , theme = Nothing
    }


activityBackgroundColor : Lens Settings Color
activityBackgroundColor =
    Compose.lensWithLens DiagramSettings.ofActivityBackgroundColor ofDiagramSettings


activityColor : Lens Settings Color
activityColor =
    Compose.lensWithLens DiagramSettings.ofActivityColor ofDiagramSettings


backgroundColor : Lens Settings Color
backgroundColor =
    Compose.lensWithLens DiagramSettings.backgroundColor ofDiagramSettings


font : Lens Settings String
font =
    Compose.lensWithLens DiagramSettings.font ofDiagramSettings


fontSize : Optional Settings Int
fontSize =
    Compose.optionalWithLens editorOfFontSize editorOfSettings


height : Lens Settings CardSize
height =
    Compose.lensWithLens DiagramSettings.ofHeight ofDiagramSettings


labelColor : Lens Settings Color
labelColor =
    Compose.lensWithLens DiagramSettings.ofLabelColor ofDiagramSettings


lineColor : Lens Settings Color
lineColor =
    Compose.lensWithLens DiagramSettings.ofLineColor ofDiagramSettings


showLineNumber : Optional Settings Bool
showLineNumber =
    Compose.optionalWithLens editorOfShowLineNumber editorOfSettings


storyBackgroundColor : Lens Settings Color
storyBackgroundColor =
    Compose.lensWithLens DiagramSettings.ofStoryBackgroundColor ofDiagramSettings


storyColor : Lens Settings Color
storyColor =
    Compose.lensWithLens DiagramSettings.ofStoryColor ofDiagramSettings


taskBackgroundColor : Lens Settings Color
taskBackgroundColor =
    Compose.lensWithLens DiagramSettings.ofTaskBackgroundColor ofDiagramSettings


taskColor : Lens Settings Color
taskColor =
    Compose.lensWithLens DiagramSettings.ofTaskColor ofDiagramSettings


textColor : Optional Settings Color
textColor =
    Compose.lensWithOptional DiagramSettings.ofTextColor ofDiagramSettings


toolbar : Lens Settings (Maybe Bool)
toolbar =
    Compose.lensWithLens DiagramSettings.toolbar ofDiagramSettings


width : Lens Settings CardSize
width =
    Compose.lensWithLens DiagramSettings.ofWidth ofDiagramSettings


wordWrap : Optional Settings Bool
wordWrap =
    Compose.optionalWithLens editorOfWordWrap editorOfSettings


zoomControl : Lens Settings (Maybe Bool)
zoomControl =
    Compose.lensWithLens DiagramSettings.zoomControl ofDiagramSettings


decoder : D.Decoder Settings
decoder =
    D.succeed Settings
        |> optional "position" (D.map Just D.int) Nothing
        |> required "font" D.string
        |> optional "diagramId" (D.map Just DiagramId.decoder) Nothing
        |> custom (D.oneOf [ D.field "storyMap" diagramDecoder, D.field "diagramSettings" diagramDecoder ])
        |> optional "text" (D.map Just Text.decoder) Nothing
        |> optional "title" (D.map Just Title.decoder) Nothing
        |> optional "editor" (D.map Just editorSettingsDecoder) Nothing
        |> optional "diagram" (D.map Just DiagramItem.decoder) Nothing
        |> optional "location" (D.map Just DiagramLocation.decoder) Nothing
        |> optional "theme" (D.map Just Theme.decoder) Nothing


encoder : Settings -> E.Value
encoder settings =
    E.object
        [ ( "position", maybe E.int settings.position )
        , ( "font", E.string settings.font )
        , ( "diagramId", maybe DiagramId.encoder settings.diagramId )
        , ( "diagramSettings", diagramEncoder settings.diagramSettings )
        , ( "text", maybe Text.encoder settings.text )
        , ( "title", maybe Title.encoder settings.title )
        , ( "editor", maybe editorSettingsEncoder settings.editor )
        , ( "diagram", maybe DiagramItem.encoder settings.diagram )
        , ( "location", maybe DiagramLocation.encoder settings.location )
        , ( "theme", maybe Theme.encoder settings.theme )
        ]


legacyEncoder : Settings -> E.Value
legacyEncoder settings =
    E.object
        [ ( "position", maybe E.int settings.position )
        , ( "font", E.string settings.font )
        , ( "diagramId", maybe DiagramId.encoder settings.diagramId )
        , ( "storyMap", diagramEncoder settings.diagramSettings )
        , ( "text", maybe Text.encoder settings.text )
        , ( "title", maybe Title.encoder settings.title )
        , ( "editor", maybe editorSettingsEncoder settings.editor )
        , ( "diagram", maybe DiagramItem.encoder settings.diagram )
        , ( "location", maybe DiagramLocation.encoder settings.location )
        , ( "theme", maybe Theme.encoder settings.theme )
        ]


exportEncoder : Settings -> E.Value
exportEncoder settings =
    E.object
        [ ( "position", maybe E.int settings.position )
        , ( "font", E.string settings.font )
        , ( "diagramSettings", diagramEncoder settings.diagramSettings )
        , ( "editor", maybe editorSettingsEncoder settings.editor )
        , ( "location", maybe DiagramLocation.encoder settings.location )
        , ( "theme", maybe Theme.encoder settings.theme )
        ]


importDecoder : Settings -> D.Decoder Settings
importDecoder settings =
    D.succeed Settings
        |> optional "position" (D.map Just D.int) Nothing
        |> required "font" D.string
        |> hardcoded settings.diagramId
        |> custom (D.oneOf [ D.field "storyMap" diagramDecoder, D.field "diagramSettings" diagramDecoder ])
        |> hardcoded settings.text
        |> hardcoded settings.title
        |> optional "editor" (D.map Just editorSettingsDecoder) Nothing
        |> hardcoded settings.diagram
        |> optional "location" (D.map Just DiagramLocation.decoder) (Just DiagramLocation.Remote)
        |> optional "theme" (D.map Just Theme.decoder) (Just <| Theme.System False)


ofDiagramSettings : Lens Settings DiagramSettings.Settings
ofDiagramSettings =
    Lens .diagramSettings (\b a -> { a | diagramSettings = b })


colorDecoder : D.Decoder DiagramSettings.ColorSetting
colorDecoder =
    D.succeed DiagramSettings.ColorSetting
        |> required "color" Color.decoder
        |> required "backgroundColor" Color.decoder


colorEncoder : DiagramSettings.ColorSetting -> E.Value
colorEncoder color =
    E.object
        [ ( "color", Color.encoder color.color )
        , ( "backgroundColor", Color.encoder color.backgroundColor )
        ]


colorSettingsDecoder : D.Decoder DiagramSettings.ColorSettings
colorSettingsDecoder =
    D.succeed DiagramSettings.ColorSettings
        |> required "activity" colorDecoder
        |> required "task" colorDecoder
        |> required "story" colorDecoder
        |> required "line" Color.decoder
        |> required "label" Color.decoder
        |> optional "text" (D.map Just Color.decoder) Nothing


colorSettingsEncoder : DiagramSettings.ColorSettings -> E.Value
colorSettingsEncoder colorSettings =
    E.object
        [ ( "activity", colorEncoder colorSettings.activity )
        , ( "task", colorEncoder colorSettings.task )
        , ( "story", colorEncoder colorSettings.story )
        , ( "line", Color.encoder colorSettings.line )
        , ( "label", Color.encoder colorSettings.label )
        , ( "text", maybe Color.encoder colorSettings.text )
        ]


diagramDecoder : D.Decoder DiagramSettings.Settings
diagramDecoder =
    D.succeed DiagramSettings.Settings
        |> required "font" D.string
        |> required "size" sizeDecoder
        |> required "color" colorSettingsDecoder
        |> required "backgroundColor" Color.decoder
        |> optional "zoomControl" (D.map Just D.bool) Nothing
        |> optional "scale" (D.map Just Scale.decoder) Nothing
        |> optional "toolbar" (D.map Just D.bool) Nothing
        |> optional "lockEditing" (D.map Just D.bool) Nothing


diagramEncoder : DiagramSettings.Settings -> E.Value
diagramEncoder settings =
    E.object
        [ ( "font", E.string settings.font )
        , ( "size", sizeEncoder settings.size )
        , ( "color", colorSettingsEncoder settings.color )
        , ( "backgroundColor", Color.encoder settings.backgroundColor )
        , ( "zoomControl", maybe E.bool settings.zoomControl )
        , ( "scale", maybe Scale.encoder settings.scale )
        , ( "toolbar", maybe E.bool settings.toolbar )
        , ( "lockEditing", maybe E.bool settings.lockEditing )
        ]


editorOfFontSize : Lens EditorSettings Int
editorOfFontSize =
    Lens .fontSize (\b a -> { a | fontSize = b })


editorOfSettings : Optional Settings EditorSettings
editorOfSettings =
    Optional .editor (\b a -> { a | editor = Just b })


editorOfShowLineNumber : Lens EditorSettings Bool
editorOfShowLineNumber =
    Lens .showLineNumber (\b a -> { a | showLineNumber = b })


editorOfWordWrap : Lens EditorSettings Bool
editorOfWordWrap =
    Lens .wordWrap (\b a -> { a | wordWrap = b })


editorSettingsDecoder : D.Decoder EditorSettings
editorSettingsDecoder =
    D.succeed EditorSettings
        |> required "fontSize" D.int
        |> required "wordWrap" D.bool
        |> required "showLineNumber" D.bool


editorSettingsEncoder : EditorSettings -> E.Value
editorSettingsEncoder editorSettings =
    E.object
        [ ( "fontSize", E.int editorSettings.fontSize )
        , ( "wordWrap", E.bool editorSettings.wordWrap )
        , ( "showLineNumber", E.bool editorSettings.showLineNumber )
        ]


sizeDecoder : D.Decoder DiagramSettings.Size
sizeDecoder =
    D.succeed DiagramSettings.Size
        |> required "width" CardSize.decoder
        |> required "height" CardSize.decoder


sizeEncoder : DiagramSettings.Size -> E.Value
sizeEncoder size =
    E.object
        [ ( "width", CardSize.encoder size.width )
        , ( "height", CardSize.encoder size.height )
        ]
