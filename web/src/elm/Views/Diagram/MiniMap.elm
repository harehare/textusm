module Views.Diagram.MiniMap exposing (..)

import Data.Size exposing (Size)
import Html exposing (Html, div)
import Html.Attributes exposing (style)
import Models.Diagram exposing (Model, Msg(..))
import Models.Views.FourLs exposing (FourLsItem(..))
import Svg exposing (Svg, svg)
import Svg.Attributes exposing (height, transform, viewBox, width)


view : Model -> Size -> Svg Msg -> Html Msg
view model ( svgWidth, svgHeight ) mainSvg =
    div
        [ style "position" "absolute"
        , style "width" "260px"
        , if model.showMiniMap then
            style "height" "150px"

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
        [ if model.showMiniMap then
            svg
                [ width "270"
                , height "150"
                , viewBox ("0 0 " ++ String.fromInt svgWidth ++ " " ++ String.fromInt svgHeight)
                , transform "translate(-90, -50), scale(0.3)"
                ]
                [ mainSvg ]

          else
            svg [] []
        ]
