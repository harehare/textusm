module Views.Diagram.MiniMap exposing (..)

import Data.Position exposing (Position)
import Data.Size exposing (Size)
import Html exposing (Html, div)
import Html.Attributes exposing (style)
import Models.Diagram exposing (Model, Msg(..))
import Models.Views.FourLs exposing (FourLsItem(..))
import Svg exposing (Svg, svg)
import Svg.Attributes exposing (fill, height, stroke, strokeWidth, transform, viewBox, width, x, y)


view : Model -> Position -> Size -> Svg Msg -> Html Msg
view model ( centerX, centerY ) ( w, h ) mainSvg =
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
        , style "border-radius" "4px"
        , style "box-shadow" "0 2px 6px rgba(5, 0, 56, 0.2)"
        , style "bottom" "16px"
        , style "right" "16px"
        , style "transition" "height 0.15s ease-out"
        ]
        [ if model.showMiniMap then
            svg
                [ width "270"
                , height "150"
                , viewBox "0 0 5760 3240"
                ]
                [ Svg.g [ transform "scale(0.7)" ]
                    [ mainSvg
                    , Svg.rect
                        [ width <| String.fromInt <| round <| toFloat w / model.svg.scale
                        , height <| String.fromInt <| round <| toFloat h / model.svg.scale
                        , x <| String.fromInt (0 - centerX)
                        , y <| String.fromInt (0 - centerY)
                        , stroke "#000000"
                        , strokeWidth "48"
                        , fill "transparent"
                        ]
                        []
                    ]
                ]

          else
            svg [] []
        ]
