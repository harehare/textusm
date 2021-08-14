module Types.DiagramLocation exposing
    ( DiagramLocation(..)
    , decoder
    , enabled
    , encoder
    , fromString
    , isGist
    , isGoogleDrive
    , isLocal
    , isRemote
    , toString
    )

import Json.Decode as D
import Json.Encode as E


type DiagramLocation
    = Local
    | Remote
    | Gist
    | GoogleDrive


type alias IsGithubUser =
    Bool


enabled : IsGithubUser -> List ( String, DiagramLocation )
enabled isGithubUser =
    if isGithubUser then
        [ ( "System", Remote )
        , ( "Github Gist", Gist )
        ]

    else
        [ ( "System", Remote )
        ]


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


decoder : D.Decoder DiagramLocation
decoder =
    D.map fromString D.string


encoder : DiagramLocation -> E.Value
encoder location =
    E.string <| toString location
