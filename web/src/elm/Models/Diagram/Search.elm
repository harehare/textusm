module Models.Diagram.Search exposing (Search, close, isSearch, search, toString, toggle)


type Search
    = Search String
    | Close


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


search : String -> Search
search query =
    Search query


toString : Search -> String
toString s =
    case s of
        Search query ->
            query

        Close ->
            ""


toggle : Search -> Search
toggle s =
    case s of
        Search _ ->
            Close

        Close ->
            Search ""
