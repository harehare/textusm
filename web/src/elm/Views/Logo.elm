module Views.Logo exposing (view)

import Asset
import Css exposing (cursor, pointer, px, width)
import Html.Styled exposing (Html, a, div, img, span, text)
import Html.Styled.Attributes exposing (alt, css, href, rel, target)
import Style.Font as Font
import Style.Style
import Style.Text as Text


view : Html msg
view =
    div [ css [ cursor pointer ] ]
        [ a
            [ css [ Style.Style.flexCenter ]
            , href "https://textusm.com"
            , target "_black"
            , rel "noopener noreferrer"
            ]
            [ img
                [ Asset.src Asset.logo
                , css [ width <| px 24 ]
                , alt "logo"
                ]
                []
            , span [ css [ Text.xs, Font.fontBold ] ] [ text "TextUSM" ]
            ]
        ]
