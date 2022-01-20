module Avatar exposing (Avatar(..), Email, ImageUrl, src, toString)

import Html.Styled exposing (Attribute)
import Html.Styled.Attributes as Attr
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
                defaultImageUrl : String
                defaultImageUrl =
                    Url.percentEncode url

                digest : String
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
