module Types.Text exposing
    ( Text
    , change
    , decoder
    , edit
    , empty
    , encoder
    , fromString
    , getLine
    , isChanged
    , isEmpty
    , map
    , replaceLine
    , saved
    , toString
    )

import Json.Decode as D exposing (Decoder)
import Json.Encode as E
import Monocle.Common exposing (list)
import Monocle.Optional exposing (modifyOption)


type Text
    = Empty
    | Changed String
    | Saved String


map : (String -> String) -> Text -> Text
map f text_ =
    text_ |> toString |> f |> fromString


change : Text -> Text
change text =
    case text of
        Empty ->
            Empty

        Changed t ->
            Changed t

        Saved t ->
            Changed t


decoder : Decoder Text
decoder =
    D.map fromString D.string


encoder : Text -> E.Value
encoder text =
    E.string <| toString text


edit : Text -> String -> Text
edit currentText newText =
    if isChanged currentText then
        Changed newText

    else if String.isEmpty newText then
        Empty

    else if
        (case currentText of
            Empty ->
                ""

            Changed t ->
                t

            Saved t ->
                t
        )
            == newText
    then
        Saved newText

    else
        Changed newText


empty : Text
empty =
    Empty


fromString : String -> Text
fromString text =
    if text == "" then
        Empty

    else
        Saved text


isChanged : Text -> Bool
isChanged text =
    case text of
        Changed _ ->
            True

        _ ->
            False


isEmpty : Text -> Bool
isEmpty text =
    text == Empty


saved : Text -> Text
saved text =
    case text of
        Empty ->
            Empty

        Changed t ->
            Saved t

        Saved t ->
            Saved t


toString : Text -> String
toString text =
    case text of
        Empty ->
            ""

        Changed t ->
            t

        Saved t ->
            t


getLine : Int -> Text -> Text
getLine index text =
    .getOption (list index) (toString text |> String.lines)
        |> Maybe.withDefault ""
        |> fromString


replaceLine : Int -> Text -> String -> Text
replaceLine index text line =
    modifyOption (list index) (\_ -> line) (toString text |> String.lines)
        |> Maybe.map (\l -> String.join "\n" l |> fromString)
        |> Maybe.withDefault text
        |> change
