module Data.ShareToken exposing (ShareToken, fromString, toString)

import Regex


type ShareToken
    = ShareToken String


fromString : String -> Maybe ShareToken
fromString token =
    let
        match =
            Regex.find
                (Maybe.withDefault Regex.never <|
                    Regex.fromString "[a-zA-Z0-9\\.\\-_=]{100,2000}"
                )
                token
                |> List.head
    in
    Maybe.andThen
        (\x ->
            if x.match == token then
                Just <| ShareToken token

            else
                Nothing
        )
        match


toString : ShareToken -> String
toString (ShareToken token) =
    token
