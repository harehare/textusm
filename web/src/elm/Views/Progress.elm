module Views.Progress exposing (view)

import Css exposing (absolute, backgroundColor, int, left, position, px, rgba, top, zIndex)
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes exposing (css)
import Style.Style as Style
import Views.Loading as Loading


view : Html msg
view =
    Html.div
        [ css
            [ position absolute
            , top <| px 0
            , left <| px 0
            , Style.fullScreen
            , Style.flexCenter
            , zIndex <| int 40
            , backgroundColor <| rgba 39 48 55 0.7
            ]
        ]
        [ Loading.view ]
