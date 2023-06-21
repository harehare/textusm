module Views.Spinner exposing (docs, view)

import Css
    exposing
        ( after
        , animationDuration
        , animationIterationCount
        , animationName
        , borderBottom3
        , borderLeft3
        , borderRadius
        , borderRight3
        , borderTop3
        , em
        , fontSize
        , height
        , hex
        , infinite
        , margin
        , pct
        , position
        , property
        , px
        , relative
        , rgba
        , sec
        , solid
        , textIndent
        , transform
        , translateZ
        , width
        , zero
        )
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
            [ margin <| px 4
            , fontSize <| px 2
            , position relative
            , textIndent <| em -9999
            , borderTop3 (em 1.1) solid (rgba 255 255 255 0.2)
            , borderRight3 (em 1.1) solid (rgba 255 255 255 0.2)
            , borderBottom3 (em 1.1) solid (rgba 255 255 255 0.2)
            , borderLeft3 (em 1.1) solid (hex "#FEFEFE")
            , transform <| translateZ zero
            , borderRadius <| pct 50
            , width <| px 16
            , height <| px 16
            , animationName <|
                keyframes
                    [ ( 0, [ Animations.property "transform" "rotate(0deg)", Animations.property "-webkit-transform" "rotate(0deg)" ] )
                    , ( 100, [ Animations.property "transform" "rotate(360deg)", Animations.property "-webkit-transform" "rotate(360deg)" ] )
                    ]
            , animationDuration <| sec 1.1
            , animationIterationCount infinite
            , property "animation-timing-function" "linear"
            , after
                [ borderRadius <| pct 50
                , width <| px 16
                , height <| px 16
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
