module Settings exposing
    ( EditorSettings
    , Settings
    , defaultEditorSettings
    , defaultSettings
    , settingsDecoder
    , settingsEncoder
    , settingsOfActivityBackgroundColor
    , settingsOfActivityColor
    , settingsOfBackgroundColor
    , settingsOfFont
    , settingsOfFontSize
    , settingsOfHeight
    , settingsOfLabelColor
    , settingsOfLineColor
    , settingsOfScale
    , settingsOfShowLineNumber
    , settingsOfStoryBackgroundColor
    , settingsOfStoryColor
    , settingsOfTaskBackgroundColor
    , settingsOfTaskColor
    , settingsOfTextColor
    , settingsOfWidth
    , settingsOfWordWrap
    , settingsOfZoomControl
    , storyMapOfSettings
    )

import Json.Decode as D
import Json.Decode.Pipeline exposing (optional, required)
import Json.Encode as E
import Json.Encode.Extra exposing (maybe)
import Models.Diagram as Diagram exposing (Color, ColorSettings, Settings, Size)
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Monocle.Optional exposing (Optional)
import Types.DiagramItem as DiagramItem exposing (DiagramItem)
import Types.DiagramLocation as DiagramLocation exposing (DiagramLocation)


type alias Settings =
    { position : Maybe Int
    , font : String
    , diagramId : Maybe String
    , storyMap : Diagram.Settings
    , text : Maybe String
    , title : Maybe String
    , editor : Maybe EditorSettings
    , diagram : Maybe DiagramItem
    , location : Maybe DiagramLocation
    }


type alias EditorSettings =
    { fontSize : Int
    , wordWrap : Bool
    , showLineNumber : Bool
    }


defaultSettings : Settings
defaultSettings =
    { position = Just -10
    , font = "Nunito Sans"
    , diagramId = Nothing
    , storyMap =
        { font = "Nunito Sans"
        , size = { width = 140, height = 65 }
        , color =
            { activity =
                { color = "#FFFFFF"
                , backgroundColor = "#266B9A"
                }
            , task =
                { color = "#FFFFFF"
                , backgroundColor = "#3E9BCD"
                }
            , story =
                { color = "#333333"
                , backgroundColor = "#FFFFFF"
                }
            , line = "#434343"
            , label = "#8C9FAE"
            , text = Just "#111111"
            }
        , backgroundColor = "#F4F4F5"
        , zoomControl = Just True
        , scale = Just 1.0
        }
    , text = Nothing
    , title = Nothing
    , editor = Nothing
    , diagram = Nothing
    , location = Nothing
    }


editorOfSettings : Optional Settings EditorSettings
editorOfSettings =
    Optional .editor (\b a -> { a | editor = Just b })


editorOfFontSize : Lens EditorSettings Int
editorOfFontSize =
    Lens .fontSize (\b a -> { a | fontSize = b })


editorOfWordWrap : Lens EditorSettings Bool
editorOfWordWrap =
    Lens .wordWrap (\b a -> { a | wordWrap = b })


editorOfShowLineNumber : Lens EditorSettings Bool
editorOfShowLineNumber =
    Lens .showLineNumber (\b a -> { a | showLineNumber = b })


settingsOfShowLineNumber : Optional Settings Bool
settingsOfShowLineNumber =
    Compose.optionalWithLens editorOfShowLineNumber editorOfSettings


settingsOfWordWrap : Optional Settings Bool
settingsOfWordWrap =
    Compose.optionalWithLens editorOfWordWrap editorOfSettings


settingsOfFontSize : Optional Settings Int
settingsOfFontSize =
    Compose.optionalWithLens editorOfFontSize editorOfSettings


settingsOfWidth : Lens Settings Int
settingsOfWidth =
    Compose.lensWithLens Diagram.settingsOfWidth storyMapOfSettings


settingsOfHeight : Lens Settings Int
settingsOfHeight =
    Compose.lensWithLens Diagram.settingsOfHeight storyMapOfSettings


settingsOfBackgroundColor : Lens Settings String
settingsOfBackgroundColor =
    Compose.lensWithLens Diagram.settingsOfBackgroundColor storyMapOfSettings


settingsOfZoomControl : Lens Settings (Maybe Bool)
settingsOfZoomControl =
    Compose.lensWithLens Diagram.settingsOfZoomControl storyMapOfSettings


settingsOfLineColor : Lens Settings String
settingsOfLineColor =
    Compose.lensWithLens Diagram.settingsOfLineColor storyMapOfSettings


settingsOfLabelColor : Lens Settings String
settingsOfLabelColor =
    Compose.lensWithLens Diagram.settingsOfLabelColor storyMapOfSettings


settingsOfTextColor : Optional Settings String
settingsOfTextColor =
    Compose.lensWithOptional Diagram.settingsOfTextColor storyMapOfSettings


settingsOfActivityColor : Lens Settings String
settingsOfActivityColor =
    Compose.lensWithLens Diagram.settingsOfActivityColor storyMapOfSettings


settingsOfTaskColor : Lens Settings String
settingsOfTaskColor =
    Compose.lensWithLens Diagram.settingsOfTaskColor storyMapOfSettings


settingsOfStoryColor : Lens Settings String
settingsOfStoryColor =
    Compose.lensWithLens Diagram.settingsOfStoryColor storyMapOfSettings


settingsOfActivityBackgroundColor : Lens Settings String
settingsOfActivityBackgroundColor =
    Compose.lensWithLens Diagram.settingsOfActivityBackgroundColor storyMapOfSettings


settingsOfTaskBackgroundColor : Lens Settings String
settingsOfTaskBackgroundColor =
    Compose.lensWithLens Diagram.settingsOfTaskBackgroundColor storyMapOfSettings


settingsOfStoryBackgroundColor : Lens Settings String
settingsOfStoryBackgroundColor =
    Compose.lensWithLens Diagram.settingsOfStoryBackgroundColor storyMapOfSettings


settingsOfFont : Lens Settings String
settingsOfFont =
    Compose.lensWithLens Diagram.settingsOfFont storyMapOfSettings


settingsOfScale : Lens Settings (Maybe Float)
settingsOfScale =
    Compose.lensWithLens Diagram.settingsOfScale storyMapOfSettings


storyMapOfSettings : Lens Settings Diagram.Settings
storyMapOfSettings =
    Lens .storyMap (\b a -> { a | storyMap = b })


defaultEditorSettings : Maybe EditorSettings -> EditorSettings
defaultEditorSettings settings =
    Maybe.withDefault
        { fontSize = 14
        , wordWrap = False
        , showLineNumber = True
        }
        settings


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
        |> optional "location" (D.map Just DiagramLocation.decoder) Nothing


diagramDecoder : D.Decoder Diagram.Settings
diagramDecoder =
    D.map6 Diagram.Settings
        (D.field "font" D.string)
        (D.field "size" sizeDecoder)
        (D.field "color" colorSettingsDecoder)
        (D.field "backgroundColor" D.string)
        (D.maybe (D.field "zoomControl" D.bool))
        (D.maybe (D.field "scale" D.float))


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
        ]


diagramEncoder : Diagram.Settings -> E.Value
diagramEncoder settings =
    E.object
        [ ( "font", E.string settings.font )
        , ( "size", sizeEncoder settings.size )
        , ( "color", colorSettingsEncoder settings.color )
        , ( "backgroundColor", E.string settings.backgroundColor )
        , ( "zoomControl", maybe E.bool settings.zoomControl )
        , ( "scale", maybe E.float settings.scale )
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
