module Data.ShareId exposing (ShareId, fromString, toString)

import Json.Decode as D exposing (Decoder)
import Regex


type ShareId
    = ShareId String


fromString : String -> Maybe ShareId
fromString id =
    let
        match =
            Regex.find
                (Maybe.withDefault Regex.never <|
                    Regex.fromString "[a-zA-Z0-9]{64}"
                )
                id
                |> List.head
    in
    Maybe.andThen
        (\x ->
            if x.match == id then
                Just <| ShareId id

            else
                Nothing
        )
        match


toString : ShareId -> String
toString (ShareId id) =
    id
