module Api.Http.Token exposing (revokeGistToken, revokeToken)

import Api.Http.Request as HttpRequest
import Api.RequestError as RequestError exposing (RequestError)
import Env
import Http
import Json.Encode as E
import Platform exposing (Task)
import Task
import Types.IdToken as IdToken exposing (IdToken)


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


revokeToken : Maybe IdToken -> Task RequestError ()
revokeToken idToken =
    HttpRequest.delete
        { url = Env.apiRoot
        , path = [ "api", "v1", "token", "revoke" ]
        , query = []
        , headers = headers idToken
        }
        Http.emptyBody
        HttpRequest.emptyResolver
        |> Task.mapError RequestError.fromHttpError


accessTokenRequestEncorder : String -> E.Value
accessTokenRequestEncorder accessToken =
    E.object
        [ ( "access_token", E.string accessToken )
        ]


headers : Maybe IdToken -> List Http.Header
headers idToken =
    case idToken of
        Just token ->
            [ Http.header "Authorization" <| IdToken.unwrap token ]

        Nothing ->
            []
