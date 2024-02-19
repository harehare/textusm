module Types.Theme exposing (IsDarkMode, Theme(..), decoder, encoder, fromString, toDisplayString, toString)

import Json.Decode as D
import Json.Encode as E


type alias IsDarkMode =
    Bool


type Theme
    = System IsDarkMode
    | Light
    | Dark


decoder : D.Decoder Theme
decoder =
    D.map fromString D.string


encoder : Theme -> E.Value
encoder theme =
    E.string <| toString theme


fromString : String -> Theme
fromString t =
    case t of
        "system" ->
            System True

        "light" ->
            Light

        "dark" ->
            Dark

        _ ->
            System True


toString : Theme -> String
toString t =
    case t of
        System _ ->
            "system"

        Light ->
            "light"

        Dark ->
            "dark"


toDisplayString : Theme -> String
toDisplayString t =
    case t of
        System _ ->
            "System"

        Light ->
            "Light"

        Dark ->
            "Dark"
