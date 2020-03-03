module Api.Api exposing (delete, emptyResolver, get, jsonResolver, post)

import Http exposing (Error(..))
import Json.Decode as D
import Models.IdToken as IdToken exposing (IdToken)
import Task exposing (Task)
import Url.Builder exposing (QueryParameter, crossOrigin)


type alias RequestInfo =
    { idToken : Maybe IdToken
    , url : String
    , path : List String
    , query : List QueryParameter
    }


get : RequestInfo -> Http.Resolver Http.Error a -> Task Http.Error a
get req resolver =
    Http.task
        { method = "GET"
        , headers =
            [ Http.header "Content-Type" "application/json"
            , req.idToken |> Maybe.withDefault (IdToken.fromString "dummy") |> IdToken.unwrap |> Http.header "Authorization"
            ]
        , url = crossOrigin req.url req.path req.query
        , body = Http.emptyBody
        , resolver = resolver
        , timeout = Nothing
        }


post : RequestInfo -> Http.Body -> Http.Resolver Http.Error a -> Task Http.Error a
post req body resolver =
    Http.task
        { method = "POST"
        , headers =
            [ Http.header "Content-Type" "application/json"
            , req.idToken |> Maybe.withDefault (IdToken.fromString "dummy") |> IdToken.unwrap |> Http.header "Authorization"
            ]
        , url = crossOrigin req.url req.path []
        , body = body
        , resolver = resolver
        , timeout = Nothing
        }


delete : RequestInfo -> Http.Resolver Http.Error a -> Task Http.Error a
delete req resolver =
    Http.task
        { method = "DELETE"
        , headers =
            [ Http.header "Content-Type" "application/json"
            , req.idToken |> Maybe.withDefault (IdToken.fromString "dummy") |> IdToken.unwrap |> Http.header "Authorization"
            ]
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
