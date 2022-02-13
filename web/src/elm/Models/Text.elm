module Models.Text exposing
    ( Text
    , addLine
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


isEmpty : Text -> Bool
isEmpty text =
    text == Empty


isChanged : Text -> Bool
isChanged text =
    case text of
        Changed _ ->
            True

        _ ->
            False


toString : Text -> String
toString text =
    case text of
        Empty ->
            ""

        Changed t ->
            t

        Saved t ->
            t


fromString : String -> Text
fromString text =
    if text == "" then
        Empty

    else
        Saved text


lines : Text -> List String
lines text =
    toString text |> String.lines


getLine : Int -> Text -> String
getLine lineNo text =
    lines text
        |> getAt lineNo
        |> Maybe.withDefault ""


addLine : Text -> String -> Text
addLine text line =
    if isEmpty text then
        Saved line

    else
        Saved <| toString text ++ "\n" ++ line


empty : Text
empty =
    Empty


saved : Text -> Text
saved text =
    case text of
        Saved t ->
            Saved t

        Changed t ->
            Saved t

        Empty ->
            Empty


change : Text -> Text
change text =
    case text of
        Saved t ->
            Changed t

        Changed t ->
            Changed t

        Empty ->
            Empty


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
