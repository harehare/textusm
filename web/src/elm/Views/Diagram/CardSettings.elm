module Views.Diagram.CardSettings exposing (State(..), view)

import Data.Color exposing (Color)
import Html exposing (Html, div)
import Html.Attributes exposing (style)


type State
    = None
    | ColorSelect
    | BackgroundColorSelect


view :
    { -- , state : State
      -- , onColorSelected : Html.Attribute msg
      -- , onBackgroundColorSelected : Html.Attribute msg
    }
    -> Html msg
view props =
    div
        [ style "width" "250px"
        , style "height" "56px"
        , style "background-color" "#F2F2F2"
        , style "box-shadow" "0 8px 16px 0 rgba(0, 0, 0, 0.12)"
        , style "transition" "height 0.2s linear, top 0.2s linear"
        , style "border-radius" "2px"
        , style "position" "absolute"
        , style "bottom" "8px"
        , style "left" "8px"
        , style "z-index" "100"
        ]
        []
