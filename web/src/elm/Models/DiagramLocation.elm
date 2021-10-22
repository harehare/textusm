module Models.DiagramLocation exposing
    ( DiagramLocation(..)
    , decoder
    , enabled
    , encoder
    , fromString
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
    | LocalFileSystem


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

        LocalFileSystem ->
            "localfilesystem"


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

        "localfilesystem" ->
            LocalFileSystem

        _ ->
            Local


decoder : D.Decoder DiagramLocation
decoder =
    D.map fromString D.string


encoder : DiagramLocation -> E.Value
encoder location =
    E.string <| toString location
