module Views.Diagram.MiniMap exposing (..)

import Html exposing (Html, div)
import Html.Attributes exposing (style)
import Models.Diagram exposing (Model, Msg(..))
import Models.Views.FourLs exposing (FourLsItem(..))


view : Model -> Html Msg
view model =
    div
        [ style "position" "absolute"
        , style "width" "260px"
        , if model.showMiniMap then
            style "height" "200px"

          else
            style "height" "0px"
        , style "background-color" "#fff"
        , style "z-index" "1"
        , style "cursor" "default"
        , style "border-radius" "8px"
        , style "box-shadow" "0 2px 6px rgba(5, 0, 56, 0.2)"
        , style "bottom" "16px"
        , style "right" "16px"
        , style "transition" "height 0.15s ease-out"
        ]
        []
