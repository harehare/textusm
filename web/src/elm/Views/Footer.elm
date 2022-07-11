module Views.Footer exposing (view)

import Css
    exposing
        ( alignItems
        , center
        , cursor
        , displayFlex
        , flexEnd
        , height
        , justifyContent
        , padding
        , pointer
        , position
        , relative
        , rem
        )
import Env
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes as Attr exposing (css)
import Models.Color as Color
import Style.Color as ColorStyle
import Style.Font as Font
import Style.Style as Style
import Style.Text as Text
import Views.Icon as Icon


view : Html msg
view =
    Html.div
        [ css
            [ height <| rem 2
            , ColorStyle.bgMain
            , Style.widthScreen
            , position relative
            , Style.shadowSm
            , displayFlex
            , alignItems center
            , justifyContent flexEnd
            , Style.borderTop0_5
            ]
        ]
        [ Html.div [ css [ padding <| rem 0.5, cursor pointer ] ]
            [ Html.a
                [ Attr.href Env.repoUrl
                , Attr.target "_blank"
                , Attr.rel "noopener noreferrer"
                ]
                [ Icon.github Color.darkIconColor 16 ]
            ]
        , Html.div
            [ css
                [ ColorStyle.textSecondaryColor
                , Text.xs
                , Font.fontBold
                , Style.paddingRightSm
                ]
            ]
            [ Html.text Env.appVersion ]
        ]
