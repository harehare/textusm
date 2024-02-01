module Models.Diagram.Settings exposing
    ( ColorSetting
    , ColorSettings
    , Settings
    , Size
    , activityBackgroundColor
    , activityColor
    , backgroundColor
    , decoder
    , default
    , encoder
    , font
    , fontFamiliy
    , fontStyle
    , getBackgroundColor
    , getCardBackgroundColor1
    , getCardBackgroundColor2
    , getCardBackgroundColor3
    , getCardForegroundColor1
    , getCardForegroundColor2
    , getCardForegroundColor3
    , getLineColor
    , getTextColor
    , height
    , labelColor
    , lineColor
    , lockEditing
    , scale
    , showGrid
    , storyBackgroundColor
    , storyColor
    , taskBackgroundColor
    , taskColor
    , textColor
    , toolbar
    , width
    , zoomControl
    )

import Css exposing (fontFamilies)
import Json.Decode as D
import Json.Decode.Pipeline exposing (optional, required)
import Json.Encode as E
import Json.Encode.Extra exposing (maybe)
import Models.Color as Color exposing (Color)
import Models.Diagram.CardSize as CardSize exposing (CardSize)
import Models.Diagram.Scale as Scale exposing (Scale)
import Models.Property as Property exposing (Property)
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Monocle.Optional exposing (Optional)


type alias ColorSetting =
    { color : Color
    , backgroundColor : Color
    }


type alias ColorSettings =
    { activity : ColorSetting
    , task : ColorSetting
    , story : ColorSetting
    , line : Color
    , label : Color
    , text : Maybe Color
    }


type alias Settings =
    { font : String
    , size : Size
    , color : ColorSettings
    , backgroundColor : Color
    , zoomControl : Maybe Bool
    , scale : Maybe Scale
    , toolbar : Maybe Bool
    , lockEditing : Maybe Bool
    , showGrid : Maybe Bool
    }


type alias Size =
    { width : CardSize
    , height : CardSize
    }


default : Settings
default =
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
        Color.backgroundDarkDefalut
    , zoomControl = Just True
    , scale = Just Scale.default
    , toolbar = Nothing
    , lockEditing = Nothing
    , showGrid = Nothing
    }


fontFamiliy : Settings -> Css.Style
fontFamiliy settings =
    fontFamilies
        [ Css.qt settings.font
        , "apple-system"
        , "BlinkMacSystemFont"
        , "Helvetica Neue"
        , "Hiragino Kaku Gothic ProN"
        , "游ゴシック Medium"
        , "YuGothic"
        , "YuGothicM"
        , "メイリオ"
        , "Meiryo"
        , "sans-serif"
        ]


fontStyle : Settings -> String
fontStyle settings =
    "'" ++ settings.font ++ "', sans-serif"


getBackgroundColor : Settings -> Property -> Color
getBackgroundColor settings property =
    Property.getBackgroundColor property
        |> Maybe.withDefault settings.backgroundColor


getCardBackgroundColor1 : Settings -> Property -> Color
getCardBackgroundColor1 settings property =
    Property.getCardBackgroundColor1 property
        |> Maybe.withDefault settings.color.activity.backgroundColor


getCardBackgroundColor2 : Settings -> Property -> Color
getCardBackgroundColor2 settings property =
    Property.getCardBackgroundColor2 property
        |> Maybe.withDefault settings.color.task.backgroundColor


getCardBackgroundColor3 : Settings -> Property -> Color
getCardBackgroundColor3 settings property =
    Property.getCardBackgroundColor3 property
        |> Maybe.withDefault settings.color.story.backgroundColor


getCardForegroundColor1 : Settings -> Property -> Color
getCardForegroundColor1 settings property =
    Property.getCardForegroundColor1 property
        |> Maybe.withDefault settings.color.activity.color


getCardForegroundColor2 : Settings -> Property -> Color
getCardForegroundColor2 settings property =
    Property.getCardForegroundColor2 property
        |> Maybe.withDefault settings.color.task.color


getCardForegroundColor3 : Settings -> Property -> Color
getCardForegroundColor3 settings property =
    Property.getCardForegroundColor3 property
        |> Maybe.withDefault settings.color.story.color


getLineColor : Settings -> Property -> Color
getLineColor settings property =
    Property.getLineColor property
        |> Maybe.withDefault settings.color.line


getTextColor : Settings -> Property -> Color
getTextColor settings property =
    Property.getTextColor property
        |> Maybe.withDefault
            (settings.color.text
                |> Maybe.withDefault
                    Color.textDefalut
            )


activityBackgroundColor : Lens Settings Color
activityBackgroundColor =
    ofColor
        |> Compose.lensWithLens colorSettingsOfActivity
        |> Compose.lensWithLens colorOfBackgroundColor


activityColor : Lens Settings Color
activityColor =
    ofColor
        |> Compose.lensWithLens colorSettingsOfActivity
        |> Compose.lensWithLens colorOfColor


backgroundColor : Lens Settings Color
backgroundColor =
    Lens .backgroundColor (\b a -> { a | backgroundColor = b })


font : Lens Settings String
font =
    Lens .font (\b a -> { a | font = b })


height : Lens Settings CardSize
height =
    Compose.lensWithLens sizeOfHeight ofSize


labelColor : Lens Settings Color
labelColor =
    ofColor
        |> Compose.lensWithLens colorSettingsOfLabel


lineColor : Lens Settings Color
lineColor =
    ofColor
        |> Compose.lensWithLens colorSettingsOfLine


scale : Lens Settings (Maybe Scale)
scale =
    Lens .scale (\b a -> { a | scale = b })


lockEditing : Lens Settings (Maybe Bool)
lockEditing =
    Lens .lockEditing (\b a -> { a | lockEditing = b })


showGrid : Lens Settings (Maybe Bool)
showGrid =
    Lens .showGrid (\b a -> { a | showGrid = b })


storyBackgroundColor : Lens Settings Color
storyBackgroundColor =
    ofColor
        |> Compose.lensWithLens colorSettingsOfStory
        |> Compose.lensWithLens colorOfBackgroundColor


storyColor : Lens Settings Color
storyColor =
    ofColor
        |> Compose.lensWithLens colorSettingsOfStory
        |> Compose.lensWithLens colorOfColor


taskBackgroundColor : Lens Settings Color
taskBackgroundColor =
    ofColor
        |> Compose.lensWithLens colorSettingsOfTask
        |> Compose.lensWithLens colorOfBackgroundColor


taskColor : Lens Settings Color
taskColor =
    ofColor
        |> Compose.lensWithLens colorSettingsOfTask
        |> Compose.lensWithLens colorOfColor


textColor : Optional Settings Color
textColor =
    ofColor
        |> Compose.lensWithOptional colorSettingsOfText


toolbar : Lens Settings (Maybe Bool)
toolbar =
    Lens .toolbar (\b a -> { a | toolbar = b })


width : Lens Settings CardSize
width =
    Compose.lensWithLens sizeOfWidth ofSize


zoomControl : Lens Settings (Maybe Bool)
zoomControl =
    Lens .zoomControl (\b a -> { a | zoomControl = b })


colorOfBackgroundColor : Lens ColorSetting Color
colorOfBackgroundColor =
    Lens .backgroundColor (\b a -> { a | backgroundColor = b })


colorOfColor : Lens ColorSetting Color
colorOfColor =
    Lens .color (\b a -> { a | color = b })


colorSettingsOfActivity : Lens ColorSettings ColorSetting
colorSettingsOfActivity =
    Lens .activity (\b a -> { a | activity = b })


colorSettingsOfLabel : Lens ColorSettings Color
colorSettingsOfLabel =
    Lens .label (\b a -> { a | label = b })


colorSettingsOfLine : Lens ColorSettings Color
colorSettingsOfLine =
    Lens .line (\b a -> { a | line = b })


colorSettingsOfStory : Lens ColorSettings ColorSetting
colorSettingsOfStory =
    Lens .story (\b a -> { a | story = b })


colorSettingsOfTask : Lens ColorSettings ColorSetting
colorSettingsOfTask =
    Lens .task (\b a -> { a | task = b })


colorSettingsOfText : Optional ColorSettings Color
colorSettingsOfText =
    Optional .text (\b a -> { a | text = Just b })


ofColor : Lens Settings ColorSettings
ofColor =
    Lens .color (\b a -> { a | color = b })


ofSize : Lens Settings Size
ofSize =
    Lens .size (\b a -> { a | size = b })


sizeOfHeight : Lens Size CardSize
sizeOfHeight =
    Lens .height (\b a -> { a | height = b })


sizeOfWidth : Lens Size CardSize
sizeOfWidth =
    Lens .width (\b a -> { a | width = b })


decoder : D.Decoder Settings
decoder =
    D.succeed Settings
        |> required "font" D.string
        |> required "size" sizeDecoder
        |> required "color" colorSettingsDecoder
        |> required "backgroundColor" Color.decoder
        |> optional "zoomControl" (D.map Just D.bool) Nothing
        |> optional "scale" (D.map Just Scale.decoder) Nothing
        |> optional "toolbar" (D.map Just D.bool) Nothing
        |> optional "lockEditing" (D.map Just D.bool) Nothing
        |> optional "showGrid" (D.map Just D.bool) Nothing


encoder : Settings -> E.Value
encoder settings =
    E.object
        [ ( "font", E.string settings.font )
        , ( "size", sizeEncoder settings.size )
        , ( "color", colorSettingsEncoder settings.color )
        , ( "backgroundColor", Color.encoder settings.backgroundColor )
        , ( "zoomControl", maybe E.bool settings.zoomControl )
        , ( "scale", maybe Scale.encoder settings.scale )
        , ( "toolbar", maybe E.bool settings.toolbar )
        , ( "lockEditing", maybe E.bool settings.lockEditing )
        , ( "showGrid", maybe E.bool settings.showGrid )
        ]


sizeDecoder : D.Decoder Size
sizeDecoder =
    D.succeed Size
        |> required "width" CardSize.decoder
        |> required "height" CardSize.decoder


sizeEncoder : Size -> E.Value
sizeEncoder size =
    E.object
        [ ( "width", CardSize.encoder size.width )
        , ( "height", CardSize.encoder size.height )
        ]


colorSettingsDecoder : D.Decoder ColorSettings
colorSettingsDecoder =
    D.succeed ColorSettings
        |> required "activity" colorDecoder
        |> required "task" colorDecoder
        |> required "story" colorDecoder
        |> required "line" Color.decoder
        |> required "label" Color.decoder
        |> optional "text" (D.map Just Color.decoder) Nothing


colorSettingsEncoder : ColorSettings -> E.Value
colorSettingsEncoder colorSettings =
    E.object
        [ ( "activity", colorEncoder colorSettings.activity )
        , ( "task", colorEncoder colorSettings.task )
        , ( "story", colorEncoder colorSettings.story )
        , ( "line", Color.encoder colorSettings.line )
        , ( "label", Color.encoder colorSettings.label )
        , ( "text", maybe Color.encoder colorSettings.text )
        ]


colorDecoder : D.Decoder ColorSetting
colorDecoder =
    D.succeed ColorSetting
        |> required "color" Color.decoder
        |> required "backgroundColor" Color.decoder


colorEncoder : ColorSetting -> E.Value
colorEncoder color =
    E.object
        [ ( "color", Color.encoder color.color )
        , ( "backgroundColor", Color.encoder color.backgroundColor )
        ]
