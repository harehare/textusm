module Models.Property exposing
    ( Property
    , empty
    , fromString
    , getBackgroundColor
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
    , getReleaseLevel
    , getTextColor
    , getTitle
    , getToolbar
    , getUserActivity
    , getUserStory
    , getUserTask
    , getZoomControl
    )

import Dict exposing (Dict)
import Models.Color as Color exposing (Color)
import Models.FontSize as FontSize exposing (FontSize)
import String exposing (toInt)


type Key
    = BackgroundColor
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


type alias Property =
    Dict String String


getBackgroundColor : Property -> Maybe Color
getBackgroundColor property =
    Dict.get (toKeyString BackgroundColor) property |> Maybe.map Color.fromString


getLineColor : Property -> Maybe Color
getLineColor property =
    Dict.get (toKeyString LineColor) property |> Maybe.map Color.fromString


getCardForegroundColor1 : Property -> Maybe Color
getCardForegroundColor1 property =
    Dict.get (toKeyString CardForegroundColor1) property |> Maybe.map Color.fromString


getCardForegroundColor2 : Property -> Maybe Color
getCardForegroundColor2 property =
    Dict.get (toKeyString CardForegroundColor2) property |> Maybe.map Color.fromString


getCardForegroundColor3 : Property -> Maybe Color
getCardForegroundColor3 property =
    Dict.get (toKeyString CardForegroundColor3) property |> Maybe.map Color.fromString


getCardBackgroundColor1 : Property -> Maybe Color
getCardBackgroundColor1 property =
    Dict.get (toKeyString CardBackgroundColor1) property |> Maybe.map Color.fromString


getCardBackgroundColor2 : Property -> Maybe Color
getCardBackgroundColor2 property =
    Dict.get (toKeyString CardBackgroundColor2) property |> Maybe.map Color.fromString


getCardBackgroundColor3 : Property -> Maybe Color
getCardBackgroundColor3 property =
    Dict.get (toKeyString CardBackgroundColor3) property |> Maybe.map Color.fromString


getLineSize : Property -> Maybe Int
getLineSize property =
    Dict.get (toKeyString LineSize) property |> Maybe.andThen toInt


getReleaseLevel : Int -> Property -> Maybe String
getReleaseLevel level property =
    Dict.get (toKeyString <| ReleaseLevel level) property


getUserActivity : Property -> Maybe String
getUserActivity property =
    Dict.get (toKeyString UserActivity) property


getUserTask : Property -> Maybe String
getUserTask property =
    Dict.get (toKeyString UserTask) property


getUserStory : Property -> Maybe String
getUserStory property =
    Dict.get (toKeyString UserStory) property


getTitle : Property -> Maybe String
getTitle property =
    Dict.get (toKeyString Title) property


getZoomControl : Property -> Maybe Bool
getZoomControl property =
    Dict.get (toKeyString ZoomControl) property |> Maybe.map (\b -> String.toLower b == "true")


getToolbar : Property -> Maybe Bool
getToolbar property =
    Dict.get (toKeyString Toolbar) property |> Maybe.map (\b -> String.toLower b == "true")


getCanvasBackgroundColor : Property -> Maybe Color
getCanvasBackgroundColor property =
    Dict.get (toKeyString CanvasBackgroundColor) property |> Maybe.map Color.fromString


getCardWidth : Property -> Maybe Int
getCardWidth property =
    Dict.get (toKeyString CardWidth) property |> Maybe.andThen toInt


getCardHeight : Property -> Maybe Int
getCardHeight property =
    Dict.get (toKeyString CardHeight) property |> Maybe.andThen toInt


getFontSize : Property -> Maybe FontSize
getFontSize property =
    Dict.get (toKeyString FontSize) property |> Maybe.andThen (\v -> toInt v |> Maybe.map FontSize.fromInt)


getTextColor : Property -> Maybe Color
getTextColor property =
    Dict.get (toKeyString TextColor) property |> Maybe.map Color.fromString


empty : Property
empty =
    Dict.empty


fromString : String -> Property
fromString text =
    String.lines text
        |> List.filterMap
            (\line ->
                if line |> String.trim |> String.startsWith "#" then
                    case String.split ":" line of
                        [ name, value ] ->
                            String.replace "#" "" name
                                |> String.trim
                                |> enabledKey
                                |> Maybe.andThen (\v -> Just ( toKeyString v, String.trim value ))

                        _ ->
                            Nothing

                else
                    Nothing
            )
        |> Dict.fromList


enabledKey : String -> Maybe Key
enabledKey s =
    case s of
        "background_color" ->
            Just BackgroundColor

        "line_color" ->
            Just LineColor

        "line_size" ->
            Just LineSize

        "user_activities" ->
            Just UserActivity

        "user_tasks" ->
            Just UserTask

        "user_stories" ->
            Just UserStory

        "title" ->
            Just Title

        "zoom_control" ->
            Just ZoomControl

        "toolbar" ->
            Just Toolbar

        "card_foreground_color1" ->
            Just CardForegroundColor1

        "card_foreground_color2" ->
            Just CardForegroundColor2

        "card_foreground_color3" ->
            Just CardForegroundColor3

        "card_background_color1" ->
            Just CardBackgroundColor1

        "card_background_color2" ->
            Just CardBackgroundColor2

        "card_background_color3" ->
            Just CardBackgroundColor3

        "canvas_background_color" ->
            Just CanvasBackgroundColor

        "card_width" ->
            Just CardWidth

        "card_height" ->
            Just CardHeight

        "text_color" ->
            Just TextColor

        "font_size" ->
            Just FontSize

        _ ->
            if String.startsWith "release" s then
                String.dropLeft 7 s |> String.toInt |> Maybe.map (\v -> ReleaseLevel v)

            else
                Nothing


toKeyString : Key -> String
toKeyString key =
    case key of
        BackgroundColor ->
            "background_color"

        LineColor ->
            "line_color"

        Title ->
            "title"

        ReleaseLevel level ->
            "release" ++ String.fromInt level

        UserActivity ->
            "user_activities"

        UserTask ->
            "user_tasks"

        UserStory ->
            "user_stories"

        ZoomControl ->
            "zoom_control"

        Toolbar ->
            "toolbar"

        LineSize ->
            "line_size"

        CardForegroundColor1 ->
            "card_foreground_color1"

        CardForegroundColor2 ->
            "card_foreground_color2"

        CardForegroundColor3 ->
            "card_foreground_color3"

        CardBackgroundColor1 ->
            "card_background_color1"

        CardBackgroundColor2 ->
            "card_background_color2"

        CardBackgroundColor3 ->
            "card_background_color3"

        CanvasBackgroundColor ->
            "canvas_background_color"

        CardWidth ->
            "card_width"

        CardHeight ->
            "card_height"

        NodeWidth ->
            "node_width"

        NodeHeight ->
            "node_heigh"

        TextColor ->
            "text_color"

        FontSize ->
            "font_size"
