module Models.Property exposing
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

import Dict exposing (Dict)
import Models.Color as Color exposing (Color)
import Models.Diagram.BackgroundImage as BgImage
import Models.FontSize as FontSize exposing (FontSize)


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
                if line |> String.trim |> String.startsWith "#" then
                    case String.split ":" line of
                        [ name, value ] ->
                            String.replace "#" "" name
                                |> String.trim
                                |> enabledKey
                                |> Maybe.map (\v -> ( toKeyString v, String.trim value ))

                        name :: rest ->
                            String.replace "#" "" name
                                |> String.trim
                                |> enabledKey
                                |> Maybe.map (\v -> ( toKeyString v, String.trim <| String.join ":" rest ))

                        _ ->
                            Nothing

                else
                    Nothing
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


enabledKey : String -> Maybe Key
enabledKey s =
    case s of
        "background_color" ->
            Just BackgroundColor

        "background_image" ->
            Just BackgroundImage

        "canvas_background_color" ->
            Just CanvasBackgroundColor

        "card_background_color1" ->
            Just CardBackgroundColor1

        "card_background_color2" ->
            Just CardBackgroundColor2

        "card_background_color3" ->
            Just CardBackgroundColor3

        "card_foreground_color1" ->
            Just CardForegroundColor1

        "card_foreground_color2" ->
            Just CardForegroundColor2

        "card_foreground_color3" ->
            Just CardForegroundColor3

        "card_height" ->
            Just CardHeight

        "card_width" ->
            Just CardWidth

        "font_size" ->
            Just FontSize

        "line_color" ->
            Just LineColor

        "line_size" ->
            Just LineSize

        "node_height" ->
            Just NodeHeight

        "node_width" ->
            Just NodeWidth

        "text_color" ->
            Just TextColor

        "title" ->
            Just Title

        "toolbar" ->
            Just Toolbar

        "user_activities" ->
            Just UserActivity

        "user_stories" ->
            Just UserStory

        "user_tasks" ->
            Just UserTask

        "zoom_control" ->
            Just ZoomControl

        _ ->
            if String.startsWith "release" s then
                String.dropLeft 7 s |> String.toInt |> Maybe.map (\v -> ReleaseLevel v)

            else
                Nothing


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
            "background_color"

        BackgroundImage ->
            "background_image"

        CardForegroundColor1 ->
            "card_foreground_color1"

        CardBackgroundColor1 ->
            "card_background_color1"

        CardForegroundColor2 ->
            "card_foreground_color2"

        CardBackgroundColor2 ->
            "card_background_color2"

        CardForegroundColor3 ->
            "card_foreground_color3"

        CardBackgroundColor3 ->
            "card_background_color3"

        CanvasBackgroundColor ->
            "canvas_background_color"

        CardWidth ->
            "card_width"

        CardHeight ->
            "card_height"

        FontSize ->
            "font_size"

        LineColor ->
            "line_color"

        LineSize ->
            "line_size"

        NodeWidth ->
            "node_width"

        NodeHeight ->
            "node_heigh"

        ReleaseLevel level ->
            "release" ++ String.fromInt level

        Title ->
            "title"

        UserActivity ->
            "user_activities"

        UserTask ->
            "user_tasks"

        UserStory ->
            "user_stories"

        Toolbar ->
            "toolbar"

        TextColor ->
            "text_color"

        ZoomControl ->
            "zoom_control"
