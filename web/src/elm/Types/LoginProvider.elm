module Types.LoginProvider exposing (LoginProvider(..), decoder, toString, isGithubLogin, isGoogleLogin)

import Json.Decode as D


type alias AccessToken =
    String


type LoginProvider
    = Google
    | Github (Maybe AccessToken)


isGithubLogin: LoginProvider -> Bool
isGithubLogin provider =
    case provider of
        Google ->
            False
        Github _ ->
            True

isGoogleLogin: LoginProvider -> Bool
isGoogleLogin provider =
    case provider of
        Google ->
            True
        Github _ ->
            False


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
        "google.com" ->
            Google

        "github.com" ->
            Github accessToken

        _ ->
            Google


decoder : D.Decoder LoginProvider
decoder =
    D.map2 from
        (D.field "provider" D.string)
        (D.maybe (D.field "accessToken" D.string))
