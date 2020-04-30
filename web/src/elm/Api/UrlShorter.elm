module Api.UrlShorter exposing (urlShorter)

import Api.Api as Api
import Data.IdToken exposing (IdToken)
import Http exposing (Error(..))
import Json.Decode as D
import Json.Encode as E
import Task exposing (Task)


type alias LongURL =
    String


requestEncoder : String -> E.Value
requestEncoder req =
    E.object
        [ ( "longDynamicLink", E.string req )
        ]


responseDecoder : D.Decoder String
responseDecoder =
    D.field "shortLink" D.string


urlShorter : Maybe IdToken -> String -> LongURL -> Task Http.Error String
urlShorter idToken apiRoot longURL =
    Api.post { idToken = idToken, url = apiRoot, path = [ "api", "urlshorter" ], query = [] } (Http.jsonBody (requestEncoder ("https://textusm.page.link/?link=" ++ longURL))) (Api.jsonResolver responseDecoder)
