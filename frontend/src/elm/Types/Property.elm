module Types.Property exposing
    ( Property
    , empty
    , fromString
    , getBackgroundColor
    , getBackgroundImage
    , getCanvasBackgroundColor
    , getCardBackgroundColor1
    , getCardBackgroundColor2
    , getCardBackgroundColor3
    , getCardForegroundColor1
    , getCardForegroundColor2
    , getCardForegroundColor3
    , getCardHeight
    , getCardWidth
    , getFontSize
    , getLineColor
    , getLineSize
    , getNodeHeight
    , getNodeWidth
    , getReleaseLevel
    , getTextColor
    , getTitle
    , getToolbar
    , getUserActivity
    , getUserStory
    , getUserTask
    , getZoomControl
    )

import Diagram.Types.BackgroundImage as BgImage
import Dict exposing (Dict)
import Parser
import Types.Color as Color exposing (Color)
import Types.FontSize as FontSize exposing (FontSize)
import Types.Property.Parser as PropertyParser


type alias Property =
    Dict String String


empty : Property
empty =
    Dict.empty


fromString : String -> Property
fromString text =
    String.lines text
        |> List.filterMap
            (\line ->
                Parser.run PropertyParser.parser line |> Result.toMaybe |> Maybe.map (\(PropertyParser.Parsed name value) -> ( name, value ))
            )
        |> Dict.fromList


getBackgroundColor : Property -> Maybe Color
getBackgroundColor property =
    Dict.get (toKeyString BackgroundColor) property |> Maybe.map Color.fromString


getBackgroundImage : Property -> Maybe BgImage.BackgroundImage
getBackgroundImage property =
    Dict.get (toKeyString BackgroundImage) property |> Maybe.andThen BgImage.fromString


getCanvasBackgroundColor : Property -> Maybe Color
getCanvasBackgroundColor property =
    Dict.get (toKeyString CanvasBackgroundColor) property |> Maybe.map Color.fromString


getCardBackgroundColor1 : Property -> Maybe Color
getCardBackgroundColor1 property =
    Dict.get (toKeyString CardBackgroundColor1) property |> Maybe.map Color.fromString


getCardBackgroundColor2 : Property -> Maybe Color
getCardBackgroundColor2 property =
    Dict.get (toKeyString CardBackgroundColor2) property |> Maybe.map Color.fromString


getCardBackgroundColor3 : Property -> Maybe Color
getCardBackgroundColor3 property =
    Dict.get (toKeyString CardBackgroundColor3) property |> Maybe.map Color.fromString


getCardForegroundColor1 : Property -> Maybe Color
getCardForegroundColor1 property =
    Dict.get (toKeyString CardForegroundColor1) property |> Maybe.map Color.fromString


getCardForegroundColor2 : Property -> Maybe Color
getCardForegroundColor2 property =
    Dict.get (toKeyString CardForegroundColor2) property |> Maybe.map Color.fromString


getCardForegroundColor3 : Property -> Maybe Color
getCardForegroundColor3 property =
    Dict.get (toKeyString CardForegroundColor3) property |> Maybe.map Color.fromString


getCardHeight : Property -> Maybe Int
getCardHeight property =
    Dict.get (toKeyString CardHeight) property |> Maybe.andThen String.toInt


getCardWidth : Property -> Maybe Int
getCardWidth property =
    Dict.get (toKeyString CardWidth) property |> Maybe.andThen String.toInt


getFontSize : Property -> Maybe FontSize
getFontSize property =
    Dict.get (toKeyString FontSize) property |> Maybe.andThen (\v -> String.toInt v |> Maybe.map FontSize.fromInt)


getLineColor : Property -> Maybe Color
getLineColor property =
    Dict.get (toKeyString LineColor) property |> Maybe.map Color.fromString


getLineSize : Property -> Maybe Int
getLineSize property =
    Dict.get (toKeyString LineSize) property |> Maybe.andThen String.toInt


getNodeHeight : Property -> Maybe Int
getNodeHeight property =
    Dict.get (toKeyString NodeHeight) property |> Maybe.andThen String.toInt


getNodeWidth : Property -> Maybe Int
getNodeWidth property =
    Dict.get (toKeyString NodeWidth) property |> Maybe.andThen String.toInt


getReleaseLevel : Int -> Property -> Maybe String
getReleaseLevel level property =
    Dict.get (toKeyString <| ReleaseLevel level) property


getTextColor : Property -> Maybe Color
getTextColor property =
    Dict.get (toKeyString TextColor) property |> Maybe.map Color.fromString


getTitle : Property -> Maybe String
getTitle property =
    Dict.get (toKeyString Title) property


getToolbar : Property -> Maybe Bool
getToolbar property =
    Dict.get (toKeyString Toolbar) property |> Maybe.map (\b -> String.toLower b == "true")


getUserActivity : Property -> Maybe String
getUserActivity property =
    Dict.get (toKeyString UserActivity) property


getUserStory : Property -> Maybe String
getUserStory property =
    Dict.get (toKeyString UserStory) property


getUserTask : Property -> Maybe String
getUserTask property =
    Dict.get (toKeyString UserTask) property


getZoomControl : Property -> Maybe Bool
getZoomControl property =
    Dict.get (toKeyString ZoomControl) property |> Maybe.map (\b -> String.toLower b == "true")


type Key
    = BackgroundColor
    | BackgroundImage
    | CardForegroundColor1
    | CardBackgroundColor1
    | CardForegroundColor2
    | CardBackgroundColor2
    | CardForegroundColor3
    | CardBackgroundColor3
    | CanvasBackgroundColor
    | CardWidth
    | CardHeight
    | FontSize
    | LineColor
    | LineSize
    | NodeWidth
    | NodeHeight
    | ReleaseLevel Int
    | Title
    | UserActivity
    | UserTask
    | UserStory
    | Toolbar
    | TextColor
    | ZoomControl


toKeyString : Key -> String
toKeyString key =
    case key of
        BackgroundColor ->
            PropertyParser.backgroundColor

        BackgroundImage ->
            PropertyParser.backgroundImage

        CardForegroundColor1 ->
            PropertyParser.cardForegroundColor1

        CardBackgroundColor1 ->
            PropertyParser.cardBackgroundColor1

        CardForegroundColor2 ->
            PropertyParser.cardForegroundColor2

        CardBackgroundColor2 ->
            PropertyParser.cardBackgroundColor2

        CardForegroundColor3 ->
            PropertyParser.cardForegroundColor3

        CardBackgroundColor3 ->
            PropertyParser.cardBackgroundColor3

        CanvasBackgroundColor ->
            PropertyParser.canvasBackgroundColor

        CardWidth ->
            PropertyParser.cardWidth

        CardHeight ->
            PropertyParser.cardHeight

        FontSize ->
            PropertyParser.fontSize

        LineColor ->
            PropertyParser.lineColor

        LineSize ->
            PropertyParser.lineSize

        NodeWidth ->
            PropertyParser.nodeWidth

        NodeHeight ->
            PropertyParser.nodeHeight

        ReleaseLevel level ->
            PropertyParser.releaseLevel level

        Title ->
            PropertyParser.title

        UserActivity ->
            PropertyParser.userActivities

        UserTask ->
            PropertyParser.userTasks

        UserStory ->
            PropertyParser.userStories

        Toolbar ->
            PropertyParser.toolbar

        TextColor ->
            PropertyParser.textColor

        ZoomControl ->
            PropertyParser.zoomControl
