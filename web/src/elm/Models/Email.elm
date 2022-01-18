module Models.Email exposing (Email, empty, fromString, toString)

import Regex


type Email
    = Email String


empty : Email
empty =
    Email ""


fromString : String -> Maybe Email
fromString s =
    let
        match : Maybe Regex.Match
        match =
            Regex.find
                (Maybe.withDefault Regex.never <|
                    Regex.fromString "^\\S+@\\S+\\.\\S+$"
                )
                s
                |> List.head
    in
    Maybe.andThen
        (\x ->
            if x.match == s then
                Just <| Email s

            else
                Nothing
        )
        match


toString : Email -> String
toString (Email m) =
    m
