module Models.Property exposing (Property, empty, fromString, getBackgroundColor)

import Dict exposing (Dict)
import Models.Color as Color exposing (Color)


type Key
    = BackgroundColor


type alias Property =
    Dict String String


getBackgroundColor : Property -> Maybe Color
getBackgroundColor property =
    Dict.get (toKeyString BackgroundColor) property |> Maybe.map Color.fromString


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
        "backgroundColor" ->
            Just BackgroundColor

        _ ->
            Nothing


toKeyString : Key -> String
toKeyString key =
    case key of
        BackgroundColor ->
            "backgroundColor"
