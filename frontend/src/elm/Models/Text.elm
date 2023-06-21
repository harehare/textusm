module Models.Text exposing
    ( Text
    , change
    , decoder
    , edit
    , empty
    , fromString
    , getLine
    , isChanged
    , isEmpty
    , lines
    , saved
    , toString
    )

import Json.Decode as D exposing (Decoder)
import List.Extra exposing (getAt)


type Text
    = Empty
    | Changed String
    | Saved String


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
    D.map
        (\t ->
            if t == "" then
                Empty

            else
                Saved t
        )
        D.string


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


getLine : Int -> Text -> String
getLine lineNo text =
    lines text
        |> getAt lineNo
        |> Maybe.withDefault ""


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


lines : Text -> List String
lines text =
    toString text |> String.lines


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
