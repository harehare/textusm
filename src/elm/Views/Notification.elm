module Views.Notification exposing (view)

import Html exposing (Html, div, text)
import Html.Attributes exposing (style)
import Models.Model exposing (Msg)


view : String -> Html Msg
view t =
    div
        [ style "position" "fixed"
        , style "top" "5%"
        , style "right" "10px"
        , style "width" "200px"
        , style "height" "40px"
        , style "background-color" "#2D2D30"
        , style "box-shadow" "0 2px 4px -1px rgba(0,0,0,.2), 0 4px 5px 0 rgba(0,0,0,.14), 0 1px 10px 0 rgba(0,0,0,.12)"
        , style "color" "#FFF"
        , style "z-index" "10"
        , style "display" "flex"
        , style "align-items" "center"
        , style "justify-content" "center"
        , style "font-size" "0.8rem"
        ]
        [ text t ]
