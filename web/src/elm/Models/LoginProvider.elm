module Models.LoginProvider exposing (AccessToken, LoginProvider(..), decoder, isGithubLogin, toString)

import Json.Decode as D
import Json.Decode.Pipeline exposing (optional, required)


type alias AccessToken =
    String


type LoginProvider
    = Google
    | Github (Maybe AccessToken)


decoder : D.Decoder LoginProvider
decoder =
    D.succeed from
        |> required "provider" D.string
        |> optional "accessToken" (D.map Just D.string) Nothing


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
