module Models.LoginProvider exposing (AccessToken, LoginProvider(..), decoder, isGithubLogin, toString)

import Json.Decode as D


type alias AccessToken =
    String


type LoginProvider
    = Google
    | Github (Maybe AccessToken)


decoder : D.Decoder LoginProvider
decoder =
    D.map2 from
        (D.field "provider" D.string)
        (D.maybe (D.field "accessToken" D.string))


isGithubLogin : LoginProvider -> Bool
isGithubLogin provider =
    case provider of
        Google ->
            False

        Github _ ->
            True


toString : LoginProvider -> String
toString provider =
    case provider of
        Google ->
            "Google"

        Github _ ->
            "Github"


from : String -> Maybe AccessToken -> LoginProvider
from provider accessToken =
    case provider of
        "github.com" ->
            Github accessToken

        "google.com" ->
            Google

        _ ->
            Google
