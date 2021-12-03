module Views.Spinner exposing (small)

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
import Html.Styled exposing (Html, div)
import Html.Styled.Attributes exposing (css)


small : Html msg
small =
    div
        [ css
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
