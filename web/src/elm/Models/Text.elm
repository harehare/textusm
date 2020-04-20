module Models.Text exposing (Text, change, edit, empty, fromString, isChanged, isEmpty, lines, saved, toString)


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
    Saved text


lines : Text -> List String
lines text =
    toString text |> String.lines


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
            Saved ""


change : Text -> Text
change text =
    case text of
        Saved t ->
            Changed t

        Changed t ->
            Changed t

        Empty ->
            Changed ""


edit : Text -> String -> Text
edit currentText newText =
    let
        text =
            case currentText of
                Empty ->
                    ""

                Changed t ->
                    t

                Saved t ->
                    t
    in
    if String.isEmpty newText then
        Empty

    else if text == newText then
        Saved newText

    else
        Changed newText
