module Models.Text exposing (Text, edit, empty, isChanged, isEmpty, lines, toString)


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


lines : Text -> List String
lines text =
    toString text |> String.lines


empty : Text
empty =
    Empty


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
