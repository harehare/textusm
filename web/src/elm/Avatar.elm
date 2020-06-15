module Avatar exposing (Avatar(..), src, toString)

import Html exposing (Attribute)
import Html.Attributes as Attr
import MD5
import Url


type alias Email =
    String


type alias ImageUrl =
    String


type Avatar
    = Avatar (Maybe Email) (Maybe ImageUrl)


toString : Avatar -> String
toString (Avatar email imageUrl) =
    case ( email, imageUrl ) of
        ( Just mail, Just url ) ->
            let
                defaultImageUrl =
                    Url.percentEncode url

                digest =
                    MD5.hex mail
            in
            "https://www.gravatar.com/avatar/" ++ digest ++ "?d=" ++ defaultImageUrl ++ "&s=40"

        ( _, Just url ) ->
            url

        _ ->
            ""


src : Avatar -> Attribute msg
src avatar =
    Attr.src <| toString avatar
