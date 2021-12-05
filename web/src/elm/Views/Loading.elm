module Views.Loading exposing (view)

import Css exposing (scale, transform)
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes exposing (css)
import Models.Color as Color
import Svg.Styled as Svg
import Svg.Styled.Attributes as SvgAttr


view : Html msg
view =
    Html.div [ css [ transform <| scale 0.2 ] ]
        [ Svg.svg
            [ SvgAttr.viewBox "0 0 320 320"
            , SvgAttr.width "320"
            , SvgAttr.height "320"
            , SvgAttr.class "active"
            ]
            [ Svg.g [ SvgAttr.style "stroke-width: 12px" ]
                [ Svg.path
                    [ SvgAttr.d "M171.81 212.32l121.33-103.35L171.81 5.62v65.52H43.14v75.83h128.67v65.35z"
                    , SvgAttr.stroke (Color.toString Color.white)
                    , SvgAttr.fill "none"
                    , SvgAttr.class "svg-elem-1"
                    ]
                    []
                , Svg.path
                    [ SvgAttr.d "M174.47 301.06L53.14 197.71 174.47 94.36v65.52h128.67v75.83H174.47v65.35z"
                    , SvgAttr.stroke (Color.toString Color.white)
                    , SvgAttr.fill "none"
                    , SvgAttr.class "svg-elem-2"
                    ]
                    []
                ]
            ]
        ]
