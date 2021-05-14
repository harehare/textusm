module Views.Logo exposing (..)

import Asset
import Html exposing (Html, a, div, img, span, text)
import Html.Attributes exposing (alt, class, href, rel, style, target)


view : Html msg
view =
    div [ class "cursor-pointer" ]
        [ a [ class "flex-center", href "https://textusm.com", target "_black", rel "noopener noreferrer" ]
            [ img [ Asset.src Asset.logo, style "width" "24px", alt "logo" ] []
            , span [ class "text-xs font-bold" ] [ text "TextUSM" ]
            ]
        ]
