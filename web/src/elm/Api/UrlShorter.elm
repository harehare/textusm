module Api.UrlShorter exposing (Request, Response, urlShorter)

import Api.Api as Api
import Data.IdToken exposing (IdToken)
import Http exposing (Error(..))
import Json.Decode as D
import Json.Encode as E
import Task exposing (Task)


type alias Request =
    { longDynamicLink : String
    }


type alias Response =
    { shortLink : String
    }


type alias LongURL =
    String


requestEncoder : Request -> E.Value
requestEncoder req =
    E.object
        [ ( "longDynamicLink", E.string req.longDynamicLink )
        ]


responseDecoder : D.Decoder Response
responseDecoder =
    D.map Response
        (D.field "shortLink" D.string)


urlShorter : Maybe IdToken -> String -> LongURL -> Task Http.Error Response
urlShorter idToken apiRoot longURL =
    Api.post { idToken = idToken, url = apiRoot, path = [ "api", "urlshorter" ], query = [] } (Http.jsonBody (requestEncoder { longDynamicLink = "https://textusm.page.link/?link=" ++ longURL })) (Api.jsonResolver responseDecoder)
