module Data.IdToken exposing
    ( IdToken
    , fromString
    , unwrap
    )


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
