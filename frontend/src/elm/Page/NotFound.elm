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
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes as Attr
import Style.Color as Color
import Style.Font as Font
import Style.Style as Style
import Style.Text as Text


view : Html msg
view =
    Html.div
        [ Attr.css
            [ Style.flexCenter
            , Text.xl
            , Font.fontSemiBold
            , Style.widthScreen
            , Color.textColor
            , height <| calc (vh 100) minus (px 40)
            , margin <| px 8
            ]
        ]
        [ Html.img [ Asset.src Asset.logo, Attr.css [ width <| px 32 ], Attr.alt "Not found" ] []
        , Html.div [ Attr.css [ padding <| px 8 ] ] [ Html.text "Not found" ]
        ]
