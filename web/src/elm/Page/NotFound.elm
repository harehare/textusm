module Page.NotFound exposing (view)

import Asset
import Css
    exposing
        ( calc
        , height
        , margin
        , minus
        , padding
        , px
        , vh
        , width
        )
import Html.Styled exposing (Html, div, img, text)
import Html.Styled.Attributes exposing (alt, css)
import Style.Color as Color
import Style.Font as Font
import Style.Style as Style
import Style.Text as Text


view : Html msg
view =
    div
        [ css
            [ Style.flexCenter
            , Text.xl
            , Font.fontSemiBold
            , Style.widthScreen
            , Color.textColor
            , height <| calc (vh 100) minus (px 40)
            , margin <| px 8
            ]
        ]
        [ img [ Asset.src Asset.logo, css [ width <| px 32 ], alt "Not found" ] []
        , div [ css [ padding <| px 8 ] ] [ text "Not found" ]
        ]
