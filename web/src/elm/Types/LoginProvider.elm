module Types.LoginProvider exposing (LoginProvider(..), toString)


type LoginProvider
    = Google
    | Github


toString : LoginProvider -> String
toString provider =
    case provider of
        Google ->
            "Google"

        Github ->
            "Github"
