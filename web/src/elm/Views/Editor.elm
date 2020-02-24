module Views.Editor exposing (view)

import Html exposing (Html, div)
import Html.Attributes exposing (id, style)
import Models.Model exposing (Msg)
import Route exposing (Route(..))


view : Html Msg
view =
    div
        [ style "background-color" "#273037"
        , style "width" "100%"
        , style "height" "100%"
        ]
        [ div
            [ id "editor"
            , style "width" "100%"
            , style "height" "100%"
            ]
            []
        ]
