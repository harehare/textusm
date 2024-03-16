module Page.NotFound exposing (view)

import Asset
import Css
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
            , Css.height <| Css.calc (Css.vh 100) Css.minus (Css.px 40)
            , Css.margin <| Css.px 8
            ]
        ]
        [ Html.img [ Asset.src Asset.logo, Attr.css [ Css.width <| Css.px 32 ], Attr.alt "Not found" ] []
        , Html.div [ Attr.css [ Css.padding <| Css.px 8 ] ] [ Html.text "Not found" ]
        ]
