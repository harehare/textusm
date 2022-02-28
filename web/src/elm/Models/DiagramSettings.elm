module Models.DiagramSettings exposing
    ( Color
    , ColorSettings
    , Settings
    , Size
    , fontFamiliy
    , fontStyle
    , ofActivityBackgroundColor
    , ofActivityColor
    , ofBackgroundColor
    , ofColor
    , ofFont
    , ofHeight
    , ofLabelColor
    , ofLineColor
    , ofScale
    , ofSize
    , ofStoryBackgroundColor
    , ofStoryColor
    , ofTaskBackgroundColor
    , ofTaskColor
    , ofTextColor
    , ofToolbar
    , ofWidth
    , ofZoomControl
    , textColor
    )

import Css exposing (fontFamilies)
import Models.Color as Color
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Monocle.Optional exposing (Optional)


type alias Settings =
    { font : String
    , size : Size
    , color : ColorSettings
    , backgroundColor : String
    , zoomControl : Maybe Bool
    , scale : Maybe Float
    , toolbar : Maybe Bool
    }


type alias ColorSettings =
    { activity : Color
    , task : Color
    , story : Color
    , line : String
    , label : String
    , text : Maybe String
    }


type alias Color =
    { color : String
    , backgroundColor : String
    }


type alias Size =
    { width : Int
    , height : Int
    }


textColor : Settings -> String
textColor settings =
    settings.color.text |> Maybe.withDefault (Color.toString Color.textDefalut)


fontStyle : Settings -> String
fontStyle settings =
    "'" ++ settings.font ++ "', sans-serif"


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


ofFont : Lens Settings String
ofFont =
    Lens .font (\b a -> { a | font = b })


ofZoomControl : Lens Settings (Maybe Bool)
ofZoomControl =
    Lens .zoomControl (\b a -> { a | zoomControl = b })


ofToolbar : Lens Settings (Maybe Bool)
ofToolbar =
    Lens .toolbar (\b a -> { a | toolbar = b })


ofScale : Lens Settings (Maybe Float)
ofScale =
    Lens .scale (\b a -> { a | scale = b })


ofBackgroundColor : Lens Settings String
ofBackgroundColor =
    Lens .backgroundColor (\b a -> { a | backgroundColor = b })


ofSize : Lens Settings Size
ofSize =
    Lens .size (\b a -> { a | size = b })


ofWidth : Lens Settings Int
ofWidth =
    Compose.lensWithLens sizeOfWidth ofSize


ofHeight : Lens Settings Int
ofHeight =
    Compose.lensWithLens sizeOfHeight ofSize


ofLineColor : Lens Settings String
ofLineColor =
    ofColor
        |> Compose.lensWithLens colorSettingsOfLine


ofTextColor : Optional Settings String
ofTextColor =
    ofColor
        |> Compose.lensWithOptional colorSettingsOfText


ofLabelColor : Lens Settings String
ofLabelColor =
    ofColor
        |> Compose.lensWithLens colorSettingsOfLabel


ofActivityColor : Lens Settings String
ofActivityColor =
    ofColor
        |> Compose.lensWithLens colorSettingsOfActivity
        |> Compose.lensWithLens colorOfColor


ofTaskColor : Lens Settings String
ofTaskColor =
    ofColor
        |> Compose.lensWithLens colorSettingsOfTask
        |> Compose.lensWithLens colorOfColor


ofStoryColor : Lens Settings String
ofStoryColor =
    ofColor
        |> Compose.lensWithLens colorSettingsOfStory
        |> Compose.lensWithLens colorOfColor


ofActivityBackgroundColor : Lens Settings String
ofActivityBackgroundColor =
    ofColor
        |> Compose.lensWithLens colorSettingsOfActivity
        |> Compose.lensWithLens colorOfBackgroundColor


ofTaskBackgroundColor : Lens Settings String
ofTaskBackgroundColor =
    ofColor
        |> Compose.lensWithLens colorSettingsOfTask
        |> Compose.lensWithLens colorOfBackgroundColor


ofStoryBackgroundColor : Lens Settings String
ofStoryBackgroundColor =
    ofColor
        |> Compose.lensWithLens colorSettingsOfStory
        |> Compose.lensWithLens colorOfBackgroundColor


ofColor : Lens Settings ColorSettings
ofColor =
    Lens .color (\b a -> { a | color = b })


colorOfColor : Lens Color String
colorOfColor =
    Lens .color (\b a -> { a | color = b })


colorOfBackgroundColor : Lens Color String
colorOfBackgroundColor =
    Lens .backgroundColor (\b a -> { a | backgroundColor = b })


colorSettingsOfActivity : Lens ColorSettings Color
colorSettingsOfActivity =
    Lens .activity (\b a -> { a | activity = b })


colorSettingsOfTask : Lens ColorSettings Color
colorSettingsOfTask =
    Lens .task (\b a -> { a | task = b })


colorSettingsOfStory : Lens ColorSettings Color
colorSettingsOfStory =
    Lens .story (\b a -> { a | story = b })


colorSettingsOfLine : Lens ColorSettings String
colorSettingsOfLine =
    Lens .line (\b a -> { a | line = b })


colorSettingsOfLabel : Lens ColorSettings String
colorSettingsOfLabel =
    Lens .label (\b a -> { a | label = b })


colorSettingsOfText : Optional ColorSettings String
colorSettingsOfText =
    Optional .text (\b a -> { a | text = Just b })


sizeOfWidth : Lens Size Int
sizeOfWidth =
    Lens .width (\b a -> { a | width = b })


sizeOfHeight : Lens Size Int
sizeOfHeight =
    Lens .height (\b a -> { a | height = b })
