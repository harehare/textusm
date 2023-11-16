module Models.Diagram.Settings exposing
    ( ColorSetting
    , ColorSettings
    , Settings
    , Size
    , default
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
    , ofActivityBackgroundColor
    , ofActivityColor
    , ofBackgroundColor
    , ofFont
    , ofHeight
    , ofLabelColor
    , ofLineColor
    , ofScale
    , ofStoryBackgroundColor
    , ofStoryColor
    , ofTaskBackgroundColor
    , ofTaskColor
    , ofTextColor
    , ofToolbar
    , ofWidth
    , ofZoomControl
    )

import Css exposing (fontFamilies)
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


getBackgroundColor : Settings -> Property -> Color.Color
getBackgroundColor settings property =
    Property.getBackgroundColor property
        |> Maybe.withDefault settings.backgroundColor


getCardBackgroundColor1 : Settings -> Property -> Color.Color
getCardBackgroundColor1 settings property =
    Property.getCardBackgroundColor1 property
        |> Maybe.withDefault settings.color.activity.backgroundColor


getCardBackgroundColor2 : Settings -> Property -> Color.Color
getCardBackgroundColor2 settings property =
    Property.getCardBackgroundColor2 property
        |> Maybe.withDefault settings.color.task.backgroundColor


getCardBackgroundColor3 : Settings -> Property -> Color.Color
getCardBackgroundColor3 settings property =
    Property.getCardBackgroundColor3 property
        |> Maybe.withDefault settings.color.story.backgroundColor


getCardForegroundColor1 : Settings -> Property -> Color.Color
getCardForegroundColor1 settings property =
    Property.getCardForegroundColor1 property
        |> Maybe.withDefault settings.color.activity.color


getCardForegroundColor2 : Settings -> Property -> Color.Color
getCardForegroundColor2 settings property =
    Property.getCardForegroundColor2 property
        |> Maybe.withDefault settings.color.task.color


getCardForegroundColor3 : Settings -> Property -> Color.Color
getCardForegroundColor3 settings property =
    Property.getCardForegroundColor3 property
        |> Maybe.withDefault settings.color.story.color


getLineColor : Settings -> Property -> Color.Color
getLineColor settings property =
    Property.getLineColor property
        |> Maybe.withDefault settings.color.line


getTextColor : Settings -> Property -> Color.Color
getTextColor settings property =
    Property.getTextColor property
        |> Maybe.withDefault
            (settings.color.text
                |> Maybe.withDefault
                    Color.textDefalut
            )


ofActivityBackgroundColor : Lens Settings Color
ofActivityBackgroundColor =
    ofColor
        |> Compose.lensWithLens colorSettingsOfActivity
        |> Compose.lensWithLens colorOfBackgroundColor


ofActivityColor : Lens Settings Color
ofActivityColor =
    ofColor
        |> Compose.lensWithLens colorSettingsOfActivity
        |> Compose.lensWithLens colorOfColor


ofBackgroundColor : Lens Settings Color
ofBackgroundColor =
    Lens .backgroundColor (\b a -> { a | backgroundColor = b })


ofFont : Lens Settings String
ofFont =
    Lens .font (\b a -> { a | font = b })


ofHeight : Lens Settings CardSize
ofHeight =
    Compose.lensWithLens sizeOfHeight ofSize


ofLabelColor : Lens Settings Color
ofLabelColor =
    ofColor
        |> Compose.lensWithLens colorSettingsOfLabel


ofLineColor : Lens Settings Color
ofLineColor =
    ofColor
        |> Compose.lensWithLens colorSettingsOfLine


ofScale : Lens Settings (Maybe Scale)
ofScale =
    Lens .scale (\b a -> { a | scale = b })


ofStoryBackgroundColor : Lens Settings Color
ofStoryBackgroundColor =
    ofColor
        |> Compose.lensWithLens colorSettingsOfStory
        |> Compose.lensWithLens colorOfBackgroundColor


ofStoryColor : Lens Settings Color
ofStoryColor =
    ofColor
        |> Compose.lensWithLens colorSettingsOfStory
        |> Compose.lensWithLens colorOfColor


ofTaskBackgroundColor : Lens Settings Color
ofTaskBackgroundColor =
    ofColor
        |> Compose.lensWithLens colorSettingsOfTask
        |> Compose.lensWithLens colorOfBackgroundColor


ofTaskColor : Lens Settings Color
ofTaskColor =
    ofColor
        |> Compose.lensWithLens colorSettingsOfTask
        |> Compose.lensWithLens colorOfColor


ofTextColor : Optional Settings Color
ofTextColor =
    ofColor
        |> Compose.lensWithOptional colorSettingsOfText


ofToolbar : Lens Settings (Maybe Bool)
ofToolbar =
    Lens .toolbar (\b a -> { a | toolbar = b })


ofWidth : Lens Settings CardSize
ofWidth =
    Compose.lensWithLens sizeOfWidth ofSize


ofZoomControl : Lens Settings (Maybe Bool)
ofZoomControl =
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
