module Settings exposing
    ( EditorSettings
    , Settings
    , defaultEditorSettings
    , defaultSettings
    , ofActivityBackgroundColor
    , ofActivityColor
    , ofBackgroundColor
    , ofFont
    , ofFontSize
    , ofHeight
    , ofLabelColor
    , ofLineColor
    , ofShowLineNumber
    , ofStoryBackgroundColor
    , ofStoryColor
    , ofTaskBackgroundColor
    , ofTaskColor
    , ofTextColor
    , ofToolbar
    , ofWidth
    , ofWordWrap
    , ofZoomControl
    , settingsDecoder
    , settingsEncoder
    , storyMapOfSettings
    )

import Json.Decode as D
import Json.Decode.Pipeline exposing (optional, required)
import Json.Encode as E
import Json.Encode.Extra exposing (maybe)
import Models.Color as Color
import Models.Diagram.Location as DiagramLocation exposing (Location)
import Models.Diagram.Settings as DiagramSettings
import Models.Diagram.Item as DiagramItem exposing (DiagramItem)
import Models.Theme as Theme exposing (Theme)
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
    , diagramId : Maybe String
    , storyMap : DiagramSettings.Settings
    , text : Maybe String
    , title : Maybe String
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
    , storyMap =
        { font = "Nunito Sans"
        , size = { width = 140, height = 65 }
        , color =
            { activity =
                { color = Color.toString Color.white
                , backgroundColor = Color.toString Color.background1Defalut
                }
            , task =
                { color = Color.toString Color.white
                , backgroundColor = Color.toString Color.background2Defalut
                }
            , story =
                { color = Color.toString Color.gray
                , backgroundColor = Color.toString Color.white
                }
            , line = Color.toString Color.lineDefalut
            , label = Color.toString Color.labelDefalut
            , text = Just <| Color.toString Color.textDefalut
            }
        , backgroundColor =
            case theme of
                Theme.System True ->
                    Color.toString Color.backgroundDarkDefalut

                Theme.System False ->
                    Color.toString Color.backgroundDefalut

                Theme.Dark ->
                    Color.toString Color.backgroundDarkDefalut

                Theme.Light ->
                    Color.toString Color.backgroundDefalut
        , zoomControl = Just True
        , scale = Just 1.0
        , toolbar = Nothing
        }
    , text = Nothing
    , title = Nothing
    , editor = Nothing
    , diagram = Nothing
    , location = Nothing
    , theme = Nothing
    }


ofActivityBackgroundColor : Lens Settings String
ofActivityBackgroundColor =
    Compose.lensWithLens DiagramSettings.ofActivityBackgroundColor storyMapOfSettings


ofActivityColor : Lens Settings String
ofActivityColor =
    Compose.lensWithLens DiagramSettings.ofActivityColor storyMapOfSettings


ofBackgroundColor : Lens Settings String
ofBackgroundColor =
    Compose.lensWithLens DiagramSettings.ofBackgroundColor storyMapOfSettings


ofFont : Lens Settings String
ofFont =
    Compose.lensWithLens DiagramSettings.ofFont storyMapOfSettings


ofFontSize : Optional Settings Int
ofFontSize =
    Compose.optionalWithLens editorOfFontSize editorOfSettings


ofHeight : Lens Settings Int
ofHeight =
    Compose.lensWithLens DiagramSettings.ofHeight storyMapOfSettings


ofLabelColor : Lens Settings String
ofLabelColor =
    Compose.lensWithLens DiagramSettings.ofLabelColor storyMapOfSettings


ofLineColor : Lens Settings String
ofLineColor =
    Compose.lensWithLens DiagramSettings.ofLineColor storyMapOfSettings


ofShowLineNumber : Optional Settings Bool
ofShowLineNumber =
    Compose.optionalWithLens editorOfShowLineNumber editorOfSettings


ofStoryBackgroundColor : Lens Settings String
ofStoryBackgroundColor =
    Compose.lensWithLens DiagramSettings.ofStoryBackgroundColor storyMapOfSettings


ofStoryColor : Lens Settings String
ofStoryColor =
    Compose.lensWithLens DiagramSettings.ofStoryColor storyMapOfSettings


ofTaskBackgroundColor : Lens Settings String
ofTaskBackgroundColor =
    Compose.lensWithLens DiagramSettings.ofTaskBackgroundColor storyMapOfSettings


ofTaskColor : Lens Settings String
ofTaskColor =
    Compose.lensWithLens DiagramSettings.ofTaskColor storyMapOfSettings


ofTextColor : Optional Settings String
ofTextColor =
    Compose.lensWithOptional DiagramSettings.ofTextColor storyMapOfSettings


ofToolbar : Lens Settings (Maybe Bool)
ofToolbar =
    Compose.lensWithLens DiagramSettings.ofToolbar storyMapOfSettings


ofWidth : Lens Settings Int
ofWidth =
    Compose.lensWithLens DiagramSettings.ofWidth storyMapOfSettings


ofWordWrap : Optional Settings Bool
ofWordWrap =
    Compose.optionalWithLens editorOfWordWrap editorOfSettings


ofZoomControl : Lens Settings (Maybe Bool)
ofZoomControl =
    Compose.lensWithLens DiagramSettings.ofZoomControl storyMapOfSettings


settingsDecoder : D.Decoder Settings
settingsDecoder =
    D.succeed Settings
        |> optional "position" (D.map Just D.int) Nothing
        |> required "font" D.string
        |> optional "diagramId" (D.map Just D.string) Nothing
        |> required "storyMap" diagramDecoder
        |> optional "text" (D.map Just D.string) Nothing
        |> optional "title" (D.map Just D.string) Nothing
        |> optional "editor" (D.map Just editorSettingsDecoder) Nothing
        |> optional "diagram" (D.map Just DiagramItem.decoder) Nothing
        |> optional "location" (D.map Just DiagramLocation.decoder) (Just DiagramLocation.Remote)
        |> optional "theme" (D.map Just Theme.decoder) (Just <| Theme.System False)


settingsEncoder : Settings -> E.Value
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
        , ( "location", maybe DiagramLocation.encoder settings.location )
        , ( "theme", maybe Theme.encoder settings.theme )
        ]


storyMapOfSettings : Lens Settings DiagramSettings.Settings
storyMapOfSettings =
    Lens .storyMap (\b a -> { a | storyMap = b })


colorDecoder : D.Decoder DiagramSettings.Color
colorDecoder =
    D.map2 DiagramSettings.Color
        (D.field "color" D.string)
        (D.field "backgroundColor" D.string)


colorEncoder : DiagramSettings.Color -> E.Value
colorEncoder color =
    E.object
        [ ( "color", E.string color.color )
        , ( "backgroundColor", E.string color.backgroundColor )
        ]


colorSettingsDecoder : D.Decoder DiagramSettings.ColorSettings
colorSettingsDecoder =
    D.map6 DiagramSettings.ColorSettings
        (D.field "activity" colorDecoder)
        (D.field "task" colorDecoder)
        (D.field "story" colorDecoder)
        (D.field "line" D.string)
        (D.field "label" D.string)
        (D.maybe (D.field "text" D.string))


colorSettingsEncoder : DiagramSettings.ColorSettings -> E.Value
colorSettingsEncoder colorSettings =
    E.object
        [ ( "activity", colorEncoder colorSettings.activity )
        , ( "task", colorEncoder colorSettings.task )
        , ( "story", colorEncoder colorSettings.story )
        , ( "line", E.string colorSettings.line )
        , ( "label", E.string colorSettings.label )
        , ( "text", maybe E.string colorSettings.text )
        ]


diagramDecoder : D.Decoder DiagramSettings.Settings
diagramDecoder =
    D.map7 DiagramSettings.Settings
        (D.field "font" D.string)
        (D.field "size" sizeDecoder)
        (D.field "color" colorSettingsDecoder)
        (D.field "backgroundColor" D.string)
        (D.maybe (D.field "zoomControl" D.bool))
        (D.maybe (D.field "scale" D.float))
        (D.maybe (D.field "toolbar" D.bool))


diagramEncoder : DiagramSettings.Settings -> E.Value
diagramEncoder settings =
    E.object
        [ ( "font", E.string settings.font )
        , ( "size", sizeEncoder settings.size )
        , ( "color", colorSettingsEncoder settings.color )
        , ( "backgroundColor", E.string settings.backgroundColor )
        , ( "zoomControl", maybe E.bool settings.zoomControl )
        , ( "scale", maybe E.float settings.scale )
        , ( "toolbar", maybe E.bool settings.toolbar )
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
    D.map3 EditorSettings
        (D.field "fontSize" D.int)
        (D.field "wordWrap" D.bool)
        (D.field "showLineNumber" D.bool)


editorSettingsEncoder : EditorSettings -> E.Value
editorSettingsEncoder editorSettings =
    E.object
        [ ( "fontSize", E.int editorSettings.fontSize )
        , ( "wordWrap", E.bool editorSettings.wordWrap )
        , ( "showLineNumber", E.bool editorSettings.showLineNumber )
        ]


sizeDecoder : D.Decoder DiagramSettings.Size
sizeDecoder =
    D.map2 DiagramSettings.Size
        (D.field "width" D.int)
        (D.field "height" D.int)


sizeEncoder : DiagramSettings.Size -> E.Value
sizeEncoder size =
    E.object
        [ ( "width", E.int size.width )
        , ( "height", E.int size.height )
        ]
