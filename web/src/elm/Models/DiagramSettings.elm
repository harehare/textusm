module Models.DiagramSettings exposing
    ( Color
    , ColorSettings
    , Settings
    , Size
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
import Graphql.Enum.Diagram exposing (Diagram(..))
import Models.Color as Color
import Models.Property as Property exposing (Property)
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Monocle.Optional exposing (Optional)


type alias Color =
    { color : String
    , backgroundColor : String
    }


type alias ColorSettings =
    { activity : Color
    , task : Color
    , story : Color
    , line : String
    , label : String
    , text : Maybe String
    }


type alias Settings =
    { font : String
    , size : Size
    , color : ColorSettings
    , backgroundColor : String
    , zoomControl : Maybe Bool
    , scale : Maybe Float
    , toolbar : Maybe Bool
    }


type alias Size =
    { width : Int
    , height : Int
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
        |> Maybe.withDefault (settings.backgroundColor |> Color.fromString)


getCardBackgroundColor1 : Settings -> Property -> Color.Color
getCardBackgroundColor1 settings property =
    Property.getCardBackgroundColor1 property
        |> Maybe.withDefault (settings.color.activity.backgroundColor |> Color.fromString)


getCardBackgroundColor2 : Settings -> Property -> Color.Color
getCardBackgroundColor2 settings property =
    Property.getCardBackgroundColor2 property
        |> Maybe.withDefault (settings.color.task.backgroundColor |> Color.fromString)


getCardBackgroundColor3 : Settings -> Property -> Color.Color
getCardBackgroundColor3 settings property =
    Property.getCardBackgroundColor3 property
        |> Maybe.withDefault (settings.color.story.backgroundColor |> Color.fromString)


getCardForegroundColor1 : Settings -> Property -> Color.Color
getCardForegroundColor1 settings property =
    Property.getCardForegroundColor1 property
        |> Maybe.withDefault (settings.color.activity.color |> Color.fromString)


getCardForegroundColor2 : Settings -> Property -> Color.Color
getCardForegroundColor2 settings property =
    Property.getCardForegroundColor2 property
        |> Maybe.withDefault (settings.color.task.color |> Color.fromString)


getCardForegroundColor3 : Settings -> Property -> Color.Color
getCardForegroundColor3 settings property =
    Property.getCardForegroundColor3 property
        |> Maybe.withDefault (settings.color.story.color |> Color.fromString)


getLineColor : Settings -> Property -> Color.Color
getLineColor settings property =
    Property.getLineColor property
        |> Maybe.withDefault (settings.color.line |> Color.fromString)


getTextColor : Settings -> Property -> Color.Color
getTextColor settings property =
    Property.getTextColor property
        |> Maybe.withDefault
            (settings.color.text
                |> Maybe.withDefault
                    (Color.textDefalut
                        |> Color.toString
                    )
                |> Color.fromString
            )


ofActivityBackgroundColor : Lens Settings String
ofActivityBackgroundColor =
    ofColor
        |> Compose.lensWithLens colorSettingsOfActivity
        |> Compose.lensWithLens colorOfBackgroundColor


ofActivityColor : Lens Settings String
ofActivityColor =
    ofColor
        |> Compose.lensWithLens colorSettingsOfActivity
        |> Compose.lensWithLens colorOfColor


ofBackgroundColor : Lens Settings String
ofBackgroundColor =
    Lens .backgroundColor (\b a -> { a | backgroundColor = b })


ofFont : Lens Settings String
ofFont =
    Lens .font (\b a -> { a | font = b })


ofHeight : Lens Settings Int
ofHeight =
    Compose.lensWithLens sizeOfHeight ofSize


ofLabelColor : Lens Settings String
ofLabelColor =
    ofColor
        |> Compose.lensWithLens colorSettingsOfLabel


ofLineColor : Lens Settings String
ofLineColor =
    ofColor
        |> Compose.lensWithLens colorSettingsOfLine


ofScale : Lens Settings (Maybe Float)
ofScale =
    Lens .scale (\b a -> { a | scale = b })


ofStoryBackgroundColor : Lens Settings String
ofStoryBackgroundColor =
    ofColor
        |> Compose.lensWithLens colorSettingsOfStory
        |> Compose.lensWithLens colorOfBackgroundColor


ofStoryColor : Lens Settings String
ofStoryColor =
    ofColor
        |> Compose.lensWithLens colorSettingsOfStory
        |> Compose.lensWithLens colorOfColor


ofTaskBackgroundColor : Lens Settings String
ofTaskBackgroundColor =
    ofColor
        |> Compose.lensWithLens colorSettingsOfTask
        |> Compose.lensWithLens colorOfBackgroundColor


ofTaskColor : Lens Settings String
ofTaskColor =
    ofColor
        |> Compose.lensWithLens colorSettingsOfTask
        |> Compose.lensWithLens colorOfColor


ofTextColor : Optional Settings String
ofTextColor =
    ofColor
        |> Compose.lensWithOptional colorSettingsOfText


ofToolbar : Lens Settings (Maybe Bool)
ofToolbar =
    Lens .toolbar (\b a -> { a | toolbar = b })


ofWidth : Lens Settings Int
ofWidth =
    Compose.lensWithLens sizeOfWidth ofSize


ofZoomControl : Lens Settings (Maybe Bool)
ofZoomControl =
    Lens .zoomControl (\b a -> { a | zoomControl = b })


colorOfBackgroundColor : Lens Color String
colorOfBackgroundColor =
    Lens .backgroundColor (\b a -> { a | backgroundColor = b })


colorOfColor : Lens Color String
colorOfColor =
    Lens .color (\b a -> { a | color = b })


colorSettingsOfActivity : Lens ColorSettings Color
colorSettingsOfActivity =
    Lens .activity (\b a -> { a | activity = b })


colorSettingsOfLabel : Lens ColorSettings String
colorSettingsOfLabel =
    Lens .label (\b a -> { a | label = b })


colorSettingsOfLine : Lens ColorSettings String
colorSettingsOfLine =
    Lens .line (\b a -> { a | line = b })


colorSettingsOfStory : Lens ColorSettings Color
colorSettingsOfStory =
    Lens .story (\b a -> { a | story = b })


colorSettingsOfTask : Lens ColorSettings Color
colorSettingsOfTask =
    Lens .task (\b a -> { a | task = b })


colorSettingsOfText : Optional ColorSettings String
colorSettingsOfText =
    Optional .text (\b a -> { a | text = Just b })


ofColor : Lens Settings ColorSettings
ofColor =
    Lens .color (\b a -> { a | color = b })


ofSize : Lens Settings Size
ofSize =
    Lens .size (\b a -> { a | size = b })


sizeOfHeight : Lens Size Int
sizeOfHeight =
    Lens .height (\b a -> { a | height = b })


sizeOfWidth : Lens Size Int
sizeOfWidth =
    Lens .width (\b a -> { a | width = b })
