module Models.Shortcuts exposing (Shortcuts(..), fromString)


type Shortcuts
    = Open
    | Save


fromString : String -> Maybe Shortcuts
fromString cmd =
    case cmd of
        "open" ->
            Just Open

        "save" ->
            Just Save

        _ ->
            Nothing
