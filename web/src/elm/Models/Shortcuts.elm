module Models.Shortcuts exposing (Shortcuts(..), fromString)


type Shortcuts
    = Open
    | Save
    | Find


fromString : String -> Maybe Shortcuts
fromString cmd =
    case cmd of
        "open" ->
            Just Open

        "save" ->
            Just Save

        "find" ->
            Just Find

        _ ->
            Nothing
