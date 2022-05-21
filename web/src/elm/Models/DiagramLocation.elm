module Models.DiagramLocation exposing
    ( CanUseNativeFileSystem
    , DiagramLocation(..)
    , IsGithubUser
    , decoder
    , enabled
    , encoder
    , fromString
    , isRemote
    , toString
    )

import Json.Decode as D
import Json.Encode as E


type alias CanUseNativeFileSystem =
    Bool


type DiagramLocation
    = Local
    | Remote
    | Gist
    | GoogleDrive
    | LocalFileSystem


type alias IsGithubUser =
    Bool


decoder : D.Decoder DiagramLocation
decoder =
    D.map fromString D.string


enabled : CanUseNativeFileSystem -> IsGithubUser -> List ( String, DiagramLocation )
enabled canUseNativeFileSystem isGithubUser =
    case ( canUseNativeFileSystem, isGithubUser ) of
        ( True, True ) ->
            [ ( "System", Remote )
            , ( "Github Gist", Gist )
            , ( "Local File System", LocalFileSystem )
            ]

        ( True, False ) ->
            [ ( "System", Remote )
            , ( "Local File System", LocalFileSystem )
            ]

        ( False, True ) ->
            [ ( "System", Remote )
            , ( "Github Gist", Gist )
            ]

        _ ->
            [ ( "System", Remote )
            ]


encoder : DiagramLocation -> E.Value
encoder location =
    E.string <| toString location


fromString : String -> DiagramLocation
fromString s =
    case s of
        "gist" ->
            Gist

        "googledrive" ->
            GoogleDrive

        "local" ->
            Local

        "localfilesystem" ->
            LocalFileSystem

        "remote" ->
            Remote

        _ ->
            Local


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
