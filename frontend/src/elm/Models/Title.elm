module Models.Title exposing (Title, edit, fromString, isEdit, isUntitled, isView, map, toString, untitled, view)


type Title
    = UnTitled
    | Edit String
    | View String


edit : Title -> Title
edit title =
    case title of
        UnTitled ->
            Edit ""

        Edit "UNTITLED" ->
            Edit ""

        Edit t ->
            Edit t

        View "UNTITLED" ->
            Edit ""

        View t ->
            Edit t


fromString : String -> Title
fromString title =
    if String.isEmpty title || title == "UNTITLED" then
        UnTitled

    else
        View title


isEdit : Title -> Bool
isEdit title =
    case title of
        Edit _ ->
            True

        _ ->
            False


isUntitled : Title -> Bool
isUntitled title =
    case title of
        UnTitled ->
            True

        Edit "UNTITLED" ->
            True

        Edit t ->
            String.isEmpty t

        View "UNTITLED" ->
            True

        View t ->
            String.isEmpty t


isView : Title -> Bool
isView title =
    case title of
        View _ ->
            True

        _ ->
            False


map : (String -> Title) -> Title -> Title
map f title =
    case title of
        UnTitled ->
            title

        Edit title_ ->
            f title_

        View title_ ->
            f title_


toString : Title -> String
toString title =
    case title of
        UnTitled ->
            "UNTITLED"

        Edit t ->
            t

        View t ->
            t


untitled : Title
untitled =
    UnTitled


view : Title -> Title
view title =
    case title of
        UnTitled ->
            View ""

        Edit "" ->
            View "UNTITLED"

        Edit t ->
            View t

        View "" ->
            View "UNTITLED"

        View t ->
            View t
