module Api.Http.Token exposing (revokeGistToken)

import Api.Http.Request as HttpRequest
import Api.RequestError as RequestError exposing (RequestError)
import Env
import Http
import Json.Encode as E
import Models.IdToken as IdToken exposing (IdToken)
import Platform exposing (Task)
import Task


accessTokenRequestEncorder : String -> E.Value
accessTokenRequestEncorder accessToken =
    E.object
        [ ( "access_token", E.string accessToken )
        ]


revokeGistToken : Maybe IdToken -> String -> Task RequestError ()
revokeGistToken idToken accessToken =
    HttpRequest.delete
        { url = Env.apiRoot
        , path = [ "api", "v1", "token", "gist", "revoke" ]
        , query = []
        , headers = headers idToken
        }
        (Http.jsonBody <| accessTokenRequestEncorder accessToken)
        HttpRequest.emptyResolver
        |> Task.mapError RequestError.fromHttpError


headers : Maybe IdToken -> List Http.Header
headers idToken =
    case idToken of
        Just token ->
            [ Http.header "Authorization" <| IdToken.unwrap token ]

        Nothing ->
            []
