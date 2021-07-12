module Api.External.Request exposing (..)

import Http exposing (Error(..), Header)
import Json.Decode as D
import Task exposing (Task)
import Url.Builder exposing (QueryParameter, crossOrigin)


type alias Request =
    { url : String
    , path : List String
    , query : List QueryParameter
    , headers : List Header
    }


get : Request -> Http.Resolver Http.Error a -> Task Http.Error a
get req resolver =
    Http.task
        { method = "GET"
        , headers = req.headers
        , url = crossOrigin req.url req.path req.query
        , body = Http.emptyBody
        , resolver = resolver
        , timeout = Nothing
        }


post : Request -> Http.Body -> Http.Resolver Http.Error a -> Task Http.Error a
post req body resolver =
    Http.task
        { method = "POST"
        , headers = req.headers
        , url = crossOrigin req.url req.path []
        , body = body
        , resolver = resolver
        , timeout = Nothing
        }


patch : Request -> Http.Body -> Http.Resolver Http.Error a -> Task Http.Error a
patch req body resolver =
    Http.task
        { method = "PATCH"
        , headers = req.headers
        , url = crossOrigin req.url req.path []
        , body = body
        , resolver = resolver
        , timeout = Nothing
        }


delete : Request -> Http.Resolver Http.Error a -> Task Http.Error a
delete req resolver =
    Http.task
        { method = "DELETE"
        , headers = req.headers
        , url = crossOrigin req.url req.path req.query
        , body = Http.emptyBody
        , resolver = resolver
        , timeout = Nothing
        }


jsonResolver : D.Decoder a -> Http.Resolver Http.Error a
jsonResolver decoder =
    Http.stringResolver <|
        \response ->
            case response of
                Http.BadUrl_ url ->
                    Err (Http.BadUrl url)

                Http.Timeout_ ->
                    Err Http.Timeout

                Http.NetworkError_ ->
                    Err Http.NetworkError

                Http.BadStatus_ metadata _ ->
                    Err (Http.BadStatus metadata.statusCode)

                Http.GoodStatus_ _ body ->
                    case D.decodeString decoder body of
                        Ok value ->
                            Ok value

                        Err err ->
                            Err (Http.BadBody (D.errorToString err))


emptyResolver : Http.Resolver Http.Error ()
emptyResolver =
    Http.stringResolver <|
        \response ->
            case response of
                Http.BadUrl_ url ->
                    Err (Http.BadUrl url)

                Http.Timeout_ ->
                    Err Http.Timeout

                Http.NetworkError_ ->
                    Err Http.NetworkError

                Http.BadStatus_ metadata _ ->
                    Err (Http.BadStatus metadata.statusCode)

                Http.GoodStatus_ _ _ ->
                    Ok ()
