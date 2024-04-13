module Types.Settings exposing
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
    , location
    , mainFont
    , showGrid
    , showLineNumber
    , splitDirection
    , storyBackgroundColor
    , storyColor
    , taskBackgroundColor
    , taskColor
    , textColor
    , theme
    , toolbar
    , width
    , wordWrap
    , zoomControl
    )

import Diagram.Types.CardSize as CardSize exposing (CardSize)
import Diagram.Types.Id as DiagramId exposing (DiagramId)
import Diagram.Types.Item as DiagramItem exposing (DiagramItem)
import Diagram.Types.Location as DiagramLocation exposing (Location)
import Diagram.Types.Scale as Scale
import Diagram.Types.Settings as DiagramSettings
import Json.Decode as D
import Json.Decode.Pipeline exposing (custom, hardcoded, optional, required)
import Json.Encode as E
import Json.Encode.Extra exposing (maybe)
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Monocle.Optional exposing (Optional)
import Types.Color as Color exposing (Color)
import Types.Font as Font exposing (Font)
import Types.FontSize as FontSize exposing (FontSize)
import Types.SplitDirection as SplitDirection exposing (SplitDirection)
import Types.Text as Text exposing (Text)
import Types.Theme as Theme exposing (Theme)
import Types.Title as Title exposing (Title)


type alias EditorSettings =
    { fontSize : FontSize
    , wordWrap : Bool
    , showLineNumber : Bool
    }


type alias Settings =
    { position : Maybe Int
    , font : Font
    , diagramId : Maybe DiagramId
    , diagramSettings : DiagramSettings.Settings
    , text : Maybe Text
    , title : Maybe Title
    , editor : Maybe EditorSettings
    , diagram : Maybe DiagramItem
    , location : Maybe Location
    , theme : Maybe Theme
    , splitDirection : Maybe SplitDirection
    }


defaultEditorSettings : Maybe EditorSettings -> EditorSettings
defaultEditorSettings settings =
    Maybe.withDefault
        { fontSize = FontSize.default
        , wordWrap = False
        , showLineNumber = True
        }
        settings


defaultSettings : Theme -> Settings
defaultSettings t =
    { position = Just -10
    , font = Font.googleFont "Nunito Sans"
    , diagramId = Nothing
    , diagramSettings =
        { font = Font.googleFont "Nunito Sans"
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
            case t of
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
        , showGrid = Nothing
        }
    , text = Nothing
    , title = Nothing
    , editor =
        Just
            { fontSize = FontSize.default
            , wordWrap = False
            , showLineNumber = True
            }
    , diagram = Nothing
    , location = Nothing
    , theme = Nothing
    , splitDirection = Nothing
    }


decoder : D.Decoder Settings
decoder =
    D.succeed Settings
        |> optional "position" (D.map Just D.int) Nothing
        |> required "font" (D.map Font.googleFont D.string)
        |> optional "diagramId" (D.map Just DiagramId.decoder) Nothing
        |> custom (D.oneOf [ D.field "storyMap" DiagramSettings.decoder, D.field "diagramSettings" DiagramSettings.decoder ])
        |> optional "text" (D.map Just Text.decoder) Nothing
        |> optional "title" (D.map Just Title.decoder) Nothing
        |> optional "editor" (D.map Just editorSettingsDecoder) Nothing
        |> optional "diagram" (D.map Just DiagramItem.decoder) Nothing
        |> optional "location" (D.map Just DiagramLocation.decoder) Nothing
        |> optional "theme" (D.map Just Theme.decoder) Nothing
        |> optional "splitDirection" (D.map Just SplitDirection.decoder) Nothing


encoder : Settings -> E.Value
encoder settings =
    E.object
        [ ( "position", maybe E.int settings.position )
        , ( "font", E.string <| Font.name settings.font )
        , ( "diagramId", maybe DiagramId.encoder settings.diagramId )
        , ( "diagramSettings", DiagramSettings.encoder settings.diagramSettings )
        , ( "text", maybe Text.encoder settings.text )
        , ( "title", maybe Title.encoder settings.title )
        , ( "editor", maybe editorSettingsEncoder settings.editor )
        , ( "diagram", maybe DiagramItem.encoder settings.diagram )
        , ( "location", maybe DiagramLocation.encoder settings.location )
        , ( "theme", maybe Theme.encoder settings.theme )
        , ( "splitDirection", maybe SplitDirection.encoder settings.splitDirection )
        ]


legacyEncoder : Settings -> E.Value
legacyEncoder settings =
    E.object
        [ ( "position", maybe E.int settings.position )
        , ( "font", E.string <| Font.name settings.font )
        , ( "diagramId", maybe DiagramId.encoder settings.diagramId )
        , ( "storyMap", DiagramSettings.encoder settings.diagramSettings )
        , ( "text", maybe Text.encoder settings.text )
        , ( "title", maybe Title.encoder settings.title )
        , ( "editor", maybe editorSettingsEncoder settings.editor )
        , ( "diagram", maybe DiagramItem.encoder settings.diagram )
        , ( "location", maybe DiagramLocation.encoder settings.location )
        , ( "theme", maybe Theme.encoder settings.theme )
        , ( "splitDirection", maybe SplitDirection.encoder settings.splitDirection )
        ]


exportEncoder : Settings -> E.Value
exportEncoder settings =
    E.object
        [ ( "position", maybe E.int settings.position )
        , ( "font", E.string <| Font.name settings.font )
        , ( "diagramSettings", DiagramSettings.encoder settings.diagramSettings )
        , ( "editor", maybe editorSettingsEncoder settings.editor )
        , ( "location", maybe DiagramLocation.encoder settings.location )
        , ( "theme", maybe Theme.encoder settings.theme )
        , ( "splitDirection", maybe SplitDirection.encoder settings.splitDirection )
        ]


importDecoder : Settings -> D.Decoder Settings
importDecoder settings =
    D.succeed Settings
        |> optional "position" (D.map Just D.int) Nothing
        |> required "font" (D.map Font.googleFont D.string)
        |> hardcoded settings.diagramId
        |> custom (D.oneOf [ D.field "storyMap" DiagramSettings.decoder, D.field "diagramSettings" DiagramSettings.decoder ])
        |> hardcoded settings.text
        |> hardcoded settings.title
        |> optional "editor" (D.map Just editorSettingsDecoder) Nothing
        |> hardcoded settings.diagram
        |> optional "location" (D.map Just DiagramLocation.decoder) (Just DiagramLocation.Remote)
        |> optional "theme" (D.map Just Theme.decoder) (Just <| Theme.System False)
        |> optional "splitDirection" (D.map Just SplitDirection.decoder) (Just SplitDirection.Horizontal)


editorSettingsDecoder : D.Decoder EditorSettings
editorSettingsDecoder =
    D.succeed EditorSettings
        |> required "fontSize" FontSize.decoder
        |> required "wordWrap" D.bool
        |> required "showLineNumber" D.bool


editorSettingsEncoder : EditorSettings -> E.Value
editorSettingsEncoder editorSettings =
    E.object
        [ ( "fontSize", E.int (FontSize.unwrap editorSettings.fontSize) )
        , ( "wordWrap", E.bool editorSettings.wordWrap )
        , ( "showLineNumber", E.bool editorSettings.showLineNumber )
        ]



-- Lens


diagramSettings : Lens Settings DiagramSettings.Settings
diagramSettings =
    Lens .diagramSettings (\b a -> { a | diagramSettings = b })


editorOfFontSize : Lens EditorSettings FontSize
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


activityBackgroundColor : Lens Settings Color
activityBackgroundColor =
    Compose.lensWithLens DiagramSettings.activityBackgroundColor diagramSettings


activityColor : Lens Settings Color
activityColor =
    Compose.lensWithLens DiagramSettings.activityColor diagramSettings


backgroundColor : Lens Settings Color
backgroundColor =
    Compose.lensWithLens DiagramSettings.backgroundColor diagramSettings


font : Lens Settings Font
font =
    Compose.lensWithLens DiagramSettings.font diagramSettings


mainFont : Lens Settings Font
mainFont =
    Lens .font (\b a -> { a | font = b })


fontSize : Optional Settings FontSize
fontSize =
    Compose.optionalWithLens editorOfFontSize editorOfSettings


height : Lens Settings CardSize
height =
    Compose.lensWithLens DiagramSettings.height diagramSettings


labelColor : Lens Settings Color
labelColor =
    Compose.lensWithLens DiagramSettings.labelColor diagramSettings


lineColor : Lens Settings Color
lineColor =
    Compose.lensWithLens DiagramSettings.lineColor diagramSettings


location : Optional Settings Location
location =
    Optional .location (\b a -> { a | location = Just b })


theme : Optional Settings Theme
theme =
    Optional .theme (\b a -> { a | theme = Just b })


splitDirection : Optional Settings SplitDirection
splitDirection =
    Optional .splitDirection (\b a -> { a | splitDirection = Just b })


showLineNumber : Optional Settings Bool
showLineNumber =
    Compose.optionalWithLens editorOfShowLineNumber editorOfSettings


storyBackgroundColor : Lens Settings Color
storyBackgroundColor =
    Compose.lensWithLens DiagramSettings.storyBackgroundColor diagramSettings


storyColor : Lens Settings Color
storyColor =
    Compose.lensWithLens DiagramSettings.storyColor diagramSettings


taskBackgroundColor : Lens Settings Color
taskBackgroundColor =
    Compose.lensWithLens DiagramSettings.taskBackgroundColor diagramSettings


taskColor : Lens Settings Color
taskColor =
    Compose.lensWithLens DiagramSettings.taskColor diagramSettings


textColor : Optional Settings Color
textColor =
    Compose.lensWithOptional DiagramSettings.textColor diagramSettings


toolbar : Lens Settings (Maybe Bool)
toolbar =
    Compose.lensWithLens DiagramSettings.toolbar diagramSettings


showGrid : Lens Settings (Maybe Bool)
showGrid =
    Compose.lensWithLens DiagramSettings.showGrid diagramSettings


width : Lens Settings CardSize
width =
    Compose.lensWithLens DiagramSettings.width diagramSettings


wordWrap : Optional Settings Bool
wordWrap =
    Compose.optionalWithLens editorOfWordWrap editorOfSettings


zoomControl : Lens Settings (Maybe Bool)
zoomControl =
    Compose.lensWithLens DiagramSettings.zoomControl diagramSettings
