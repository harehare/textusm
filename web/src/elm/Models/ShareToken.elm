module Models.ShareToken exposing (ShareToken, fromString, toString, unwrap)

import Base64
import Regex
import UrlBase64


type ShareToken
    = ShareToken String


fromString : String -> Maybe ShareToken
fromString token =
    let
        match : Maybe Regex.Match
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


unwrap : ShareToken -> Maybe String
unwrap (ShareToken token) =
    UrlBase64.decode Base64.decode token |> Result.toMaybe


toString : ShareToken -> String
toString (ShareToken token) =
    token
