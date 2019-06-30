module Api.Api exposing (delete, emptyResolver, get, jsonResolver, post)

import Http exposing (Error(..))
import Json.Decode as D
import Models.IdToken as IdToken exposing (IdToken)
import Task exposing (Task)
import Url.Builder exposing (QueryParameter, crossOrigin)


get : Maybe IdToken -> String -> List String -> List QueryParameter -> Http.Resolver Http.Error a -> Task Http.Error a
get idToken apiRoot path query resolver =
    Http.task
        { method = "GET"
        , headers =
            [ Http.header "Content-Type" "application/json"
            , case idToken of
                Just i ->
                    IdToken.unwrap i |> Http.header "Authorization"

                Nothing ->
                    Http.header "Authorization" "dummy"
            ]
        , url = crossOrigin apiRoot path query
        , body = Http.emptyBody
        , resolver = resolver
        , timeout = Nothing
        }


post : Maybe IdToken -> String -> List String -> Http.Body -> Http.Resolver Http.Error a -> Task Http.Error a
post idToken apiRoot path body resolver =
    Http.task
        { method = "POST"
        , headers =
            [ Http.header "Content-Type" "application/json"
            , case idToken of
                Just i ->
                    IdToken.unwrap i |> Http.header "Authorization"

                Nothing ->
                    Http.header "Authorization" "dummy"
            ]
        , url = crossOrigin apiRoot path []
        , body = body
        , resolver = resolver
        , timeout = Nothing
        }


delete : Maybe IdToken -> String -> List String -> List QueryParameter -> Http.Resolver Http.Error a -> Task Http.Error a
delete idToken apiRoot path query resolver =
    Http.task
        { method = "DELETE"
        , headers =
            [ Http.header "Content-Type" "application/json"
            , case idToken of
                Just i ->
                    IdToken.unwrap i |> Http.header "Authorization"

                Nothing ->
                    Http.header "Authorization" "dummy"
            ]
        , url = crossOrigin apiRoot path query
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
