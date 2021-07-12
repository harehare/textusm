module Types.DiagramLocation exposing (DiagramLocation(..), fromString, isGist, isGoogleDrive, isLocal, isRemote, toString)


type DiagramLocation
    = Local
    | Remote
    | Gist
    | GoogleDrive


isRemote : DiagramLocation -> Bool
isRemote loc =
    case loc of
        Remote ->
            True

        _ ->
            False


isLocal : DiagramLocation -> Bool
isLocal loc =
    case loc of
        Local ->
            True

        _ ->
            False


isGist : DiagramLocation -> Bool
isGist loc =
    case loc of
        Gist ->
            True

        _ ->
            False


isGoogleDrive : DiagramLocation -> Bool
isGoogleDrive loc =
    case loc of
        GoogleDrive ->
            True

        _ ->
            False


toString : DiagramLocation -> String
toString loc =
    case loc of
        Local ->
            "local"

        Remote ->
            "remote"

        Gist ->
            "gist"

        GoogleDrive ->
            "googledrive"


fromString : String -> DiagramLocation
fromString s =
    case s of
        "local" ->
            Local

        "remote" ->
            Remote

        "gist" ->
            Gist

        "googledrive" ->
            GoogleDrive

        _ ->
            Local
