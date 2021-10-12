module Models.ShareState exposing
    ( ShareState
    , authenticateNoPassword
    , authenticateWithPassword
    , authenticated
    , authenticatedError
    , getError
    , getPassword
    , getToken
    , inputPassword
    , isAuthenticated
    , unauthorized
    )

import Api.RequestError exposing (RequestError)
import Models.ShareToken exposing (ShareToken)


type ShareState
    = Authenticated
    | AuthenticatedError RequestError
    | AuthenticateNoPassword ShareToken
    | AuthenticateWithPassword ShareToken String
    | Unauthorized


isAuthenticated : ShareState -> Bool
isAuthenticated state =
    case state of
        Authenticated ->
            True

        _ ->
            False


getPassword : ShareState -> Maybe String
getPassword state =
    case state of
        AuthenticateWithPassword _ password ->
            Just password

        _ ->
            Nothing


getToken : ShareState -> Maybe ShareToken
getToken state =
    case state of
        AuthenticateWithPassword token _ ->
            Just token

        AuthenticateNoPassword token ->
            Just token

        _ ->
            Nothing


getError : ShareState -> Maybe RequestError
getError state =
    case state of
        AuthenticatedError err ->
            Just err

        _ ->
            Nothing


inputPassword : ShareState -> String -> ShareState
inputPassword shareState password =
    case shareState of
        AuthenticateWithPassword token _ ->
            AuthenticateWithPassword token password

        _ ->
            Unauthorized


authenticateNoPassword : ShareToken -> ShareState
authenticateNoPassword token =
    AuthenticateNoPassword token


authenticateWithPassword : ShareToken -> ShareState
authenticateWithPassword token =
    AuthenticateWithPassword token ""


unauthorized : ShareState
unauthorized =
    Unauthorized


authenticated : ShareState -> ShareState
authenticated state =
    case state of
        AuthenticateNoPassword _ ->
            Authenticated

        AuthenticateWithPassword _ _ ->
            Authenticated

        _ ->
            Unauthorized


authenticatedError : RequestError -> ShareState
authenticatedError error =
    AuthenticatedError error
