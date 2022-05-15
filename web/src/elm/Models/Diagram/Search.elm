module Models.Diagram.Search exposing (Search, close, isSearch, search, toString, toggle)


type Search
    = Search String
    | Close


search : String -> Search
search query =
    Search query


close : Search
close =
    Close


isSearch : Search -> Bool
isSearch s =
    case s of
        Search _ ->
            True

        Close ->
            False


toggle : Search -> Search
toggle s =
    case s of
        Search _ ->
            Close

        Close ->
            Search ""


toString : Search -> String
toString s =
    case s of
        Search query ->
            query

        Close ->
            ""
