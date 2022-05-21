module Api.External.Github.Request exposing (AccessToken, GistId, createGist, deleteGist, getGist, updateGist)

import Api.External.Github.Gist as Gist exposing (Gist)
import Api.External.Github.GistInput as GistInput exposing (GistInput)
import Api.Http.Request as Request
import Http exposing (Header)
import Json.Encode as E
import Task exposing (Task)


type alias AccessToken =
    String


type alias GistId =
    String


createGist : AccessToken -> GistInput -> Task Http.Error Gist
createGist accessToken gist =
    Request.post
        { url = hostName
        , path = [ gistPath ]
        , query = []
        , headers = headers accessToken
        }
        (Http.jsonBody <| GistInput.encoder gist)
        (Request.jsonResolver Gist.decoder)


deleteGist : AccessToken -> GistId -> Task Http.Error ()
deleteGist accessToken gistId =
    Request.delete
        { url = hostName
        , path = [ gistPath, gistId ]
        , query = []
        , headers = headers accessToken
        }
        (Http.jsonBody <| E.object [ ( "gistId", E.string gistId ) ])
        Request.emptyResolver


getGist : AccessToken -> GistId -> Task Http.Error Gist
getGist accessToken gistId =
    Request.get
        { url = hostName
        , path = [ gistPath, gistId ]
        , query = []
        , headers = headers accessToken
        }
    <|
        Request.jsonResolver Gist.decoder


updateGist : AccessToken -> GistId -> GistInput -> Task Http.Error Gist
updateGist accessToken gistId gist =
    Request.patch
        { url = hostName
        , path = [ gistPath, gistId ]
        , query = []
        , headers = headers accessToken
        }
        (Http.jsonBody <| GistInput.encoder gist)
        (Request.jsonResolver Gist.decoder)


gistPath : String
gistPath =
    "gists"


headers : AccessToken -> List Header
headers accessToken =
    [ Http.header "Accept" "application/vnd.github.v3+json"
    , Http.header "Authorization" <| "token " ++ accessToken
    ]


hostName : String
hostName =
    "https://api.github.com"
