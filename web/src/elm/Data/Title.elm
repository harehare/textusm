module Data.Title exposing (Title, edit, fromString, isEdit, isUntitled, isView, toString, untitled, view)


type Title
    = UnTitled
    | Edit String
    | View String


isUntitled : Title -> Bool
isUntitled title =
    case title of
        UnTitled ->
            True

        View "UNTITLED" ->
            True

        Edit "UNTITLED" ->
            True

        Edit t ->
            String.isEmpty t

        View t ->
            String.isEmpty t


isView : Title -> Bool
isView title =
    case title of
        View _ ->
            True

        _ ->
            False


isEdit : Title -> Bool
isEdit title =
    case title of
        Edit _ ->
            True

        _ ->
            False


untitled : Title
untitled =
    UnTitled


edit : Title -> Title
edit title =
    case title of
        UnTitled ->
            Edit ""

        View "UNTITLED" ->
            Edit ""

        Edit "UNTITLED" ->
            Edit ""

        View t ->
            Edit t

        Edit t ->
            Edit t


view : Title -> Title
view title =
    case title of
        UnTitled ->
            View ""

        View "" ->
            View "UNTITLED"

        Edit "" ->
            View "UNTITLED"

        View t ->
            View t

        Edit t ->
            View t


toString : Title -> String
toString title =
    case title of
        UnTitled ->
            "UNTITLED"

        View t ->
            t

        Edit t ->
            t


fromString : String -> Title
fromString title =
    if String.isEmpty title || title == "UNTITLED" then
        UnTitled

    else
        View title
