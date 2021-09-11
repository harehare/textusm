module Models.IdToken exposing
    ( IdToken
    , decoder
    , fromString
    , unwrap
    )

import Json.Decode as D


type IdToken
    = IdToken String


fromString : String -> IdToken
fromString string =
    if String.startsWith "Bearer " string then
        IdToken string

    else
        IdToken ("Bearer " ++ string)


unwrap : IdToken -> String
unwrap (IdToken string) =
    string


decoder : D.Decoder IdToken
decoder =
    D.map IdToken D.string
