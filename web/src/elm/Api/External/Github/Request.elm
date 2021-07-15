module Api.External.Github.Request exposing (..)

import Api.External.Github.Gist as Gist exposing (Gist)
import Api.External.Request as Request
import Http exposing (Header)
import Task exposing (Task)
import Url.Builder as Url


hostName : String
hostName =
    "https://api.github.com"


headers : String -> List Header
headers accessToken =
    [ Http.header "Accept" "application/vnd.github.v3+json"
    , Http.header "Authorization" <| "token" ++ accessToken
    ]


gistPath : String
gistPath =
    "/gists"


getGist : String -> String -> Task Http.Error Gist
getGist accessToken gistId =
    Request.get
        { url = hostName
        , path = [ gistPath, gistId ]
        , query = []
        , headers = headers accessToken
        }
    <|
        Request.jsonResolver Gist.decoder
