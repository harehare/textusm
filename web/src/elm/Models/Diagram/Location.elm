module Models.Diagram.Location exposing
    ( CanUseNativeFileSystem
    , IsGithubUser
    , Location(..)
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


type Location
    = Local
    | Remote
    | Gist
    | LocalFileSystem


type alias IsGithubUser =
    Bool


decoder : D.Decoder Location
decoder =
    D.map fromString D.string


enabled : CanUseNativeFileSystem -> IsGithubUser -> List ( String, Location )
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


encoder : Location -> E.Value
encoder location =
    E.string <| toString location


fromString : String -> Location
fromString s =
    case s of
        "gist" ->
            Gist

        "local" ->
            Local

        "localfilesystem" ->
            LocalFileSystem

        "remote" ->
            Remote

        _ ->
            Local


isRemote : Location -> Bool
isRemote loc =
    case loc of
        Remote ->
            True

        _ ->
            False


toString : Location -> String
toString loc =
    case loc of
        Local ->
            "local"

        Remote ->
            "remote"

        Gist ->
            "gist"

        LocalFileSystem ->
            "localfilesystem"
