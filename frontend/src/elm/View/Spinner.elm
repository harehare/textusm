module View.Spinner exposing (docs, view)

import Css
import Css.Animations as Animations exposing (keyframes)
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes as Attr
import Style.Color as ColorStyle
import Style.Style


view : Html msg
view =
    Html.div
        [ Attr.css
            [ Css.margin <| Css.px 4
            , Css.fontSize <| Css.px 2
            , Css.position Css.relative
            , Css.textIndent <| Css.em -9999
            , Css.borderTop3 (Css.em 1.1) Css.solid (Css.rgba 255 255 255 0.2)
            , Css.borderRight3 (Css.em 1.1) Css.solid (Css.rgba 255 255 255 0.2)
            , Css.borderBottom3 (Css.em 1.1) Css.solid (Css.rgba 255 255 255 0.2)
            , Css.borderLeft3 (Css.em 1.1) Css.solid (Css.hex "#FEFEFE")
            , Css.transform <| Css.translateZ Css.zero
            , Css.borderRadius <| Css.pct 50
            , Css.width <| Css.px 16
            , Css.height <| Css.px 16
            , Css.animationName <|
                keyframes
                    [ ( 0, [ Animations.property "transform" "rotate(0deg)", Animations.property "-webkit-transform" "rotate(0deg)" ] )
                    , ( 100, [ Animations.property "transform" "rotate(360deg)", Animations.property "-webkit-transform" "rotate(360deg)" ] )
                    ]
            , Css.animationDuration <| Css.sec 1.1
            , Css.animationIterationCount Css.infinite
            , Css.property "animation-timing-function" "linear"
            , Css.after
                [ Css.borderRadius <| Css.pct 50
                , Css.width <| Css.px 16
                , Css.height <| Css.px 16
                ]
            ]
        ]
        []


docs : Chapter x
docs =
    Chapter.chapter "Spinner"
        |> Chapter.renderComponentList
            [ ( "Spinner"
              , Html.div [ Attr.css [ ColorStyle.bgMain, Style.Style.paddingSm ] ] [ view ] |> Html.toUnstyled
              )
            ]
