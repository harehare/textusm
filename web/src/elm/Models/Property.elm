module Models.Property exposing
    ( Property
    , empty
    , fromString
    , getBackgroundColor
    , getReleaseLevel
    , getTitle
    , getUserActivity
    , getUserStory
    , getUserTask
    , getZoomControl
    )

import Dict exposing (Dict)
import Models.Color as Color exposing (Color)


type Key
    = BackgroundColor
    | Title
    | UserActivity
    | UserTask
    | UserStory
    | ReleaseLevel Int
    | ZoomControl


type alias Property =
    Dict String String


getBackgroundColor : Property -> Maybe Color
getBackgroundColor property =
    Dict.get (toKeyString BackgroundColor) property |> Maybe.map Color.fromString


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
