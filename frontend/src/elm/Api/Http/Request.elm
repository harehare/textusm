module Api.Http.Request exposing (Request, delete, emptyResolver, get, jsonResolver, patch, post)

import Http exposing (Header)
import Json.Decode as D
import Task exposing (Task)
import Url.Builder exposing (QueryParameter, crossOrigin)


type alias Request =
    { url : String
    , path : List String
    , query : List QueryParameter
    , headers : List Header
    }


delete : Request -> Http.Body -> Http.Resolver Http.Error a -> Task Http.Error a
delete req body resolver =
    Http.task
        { body = body
        , headers = req.headers
        , method = "DELETE"
        , resolver = resolver
        , timeout = Nothing
        , url = crossOrigin req.url req.path req.query
        }


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


get : Request -> Http.Resolver Http.Error a -> Task Http.Error a
get req resolver =
    Http.task
        { body = Http.emptyBody
        , headers = req.headers
        , method = "GET"
        , resolver = resolver
        , timeout = Nothing
        , url = crossOrigin req.url req.path req.query
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


patch : Request -> Http.Body -> Http.Resolver Http.Error a -> Task Http.Error a
patch req body resolver =
    Http.task
        { body = body
        , headers = req.headers
        , method = "PATCH"
        , resolver = resolver
        , timeout = Nothing
        , url = crossOrigin req.url req.path []
        }


post : Request -> Http.Body -> Http.Resolver Http.Error a -> Task Http.Error a
post req body resolver =
    Http.task
        { body = body
        , headers = req.headers
        , method = "POST"
        , resolver = resolver
        , timeout = Nothing
        , url = crossOrigin req.url req.path []
        }
