module Views.Diagram.MiniMap exposing (..)

import Data.Position exposing (Position)
import Data.Size exposing (Size)
import Html exposing (Html, div)
import Html.Attributes as Attr
import Models.Diagram exposing (Model, Msg(..))
import Models.Views.FourLs exposing (FourLsItem(..))
import Svg exposing (Svg, svg)
import Svg.Attributes exposing (class, fill, height, stroke, strokeWidth, transform, viewBox, width, x, y)


view : Model -> Position -> Size -> Svg Msg -> Html Msg
view model ( centerX, centerY ) ( w, h ) mainSvg =
    div
        [ Attr.class "mini-map"
        , Attr.style "position" "absolute"
        , Attr.style "width" "260px"
        , if model.showMiniMap then
            Attr.style "height" "150px"

          else
            Attr.style "height" "0px"
        , Attr.style "background-color" "#fff"
        , Attr.style "z-index" "1"
        , Attr.style "cursor" "default"
        , Attr.style "border-radius" "2px"
        , Attr.style "box-shadow" "0 2px 6px rgba(5, 0, 56, 0.2)"
        , Attr.style "bottom" "16px"
        , Attr.style "right" "16px"
        , Attr.style "transition" "height 0.15s ease-out"
        ]
        [ if model.showMiniMap then
            svg
                [ width "270"
                , height "150"
                , viewBox "0 0 2880 1620"
                ]
                [ Svg.g [ transform "scale(0.4)" ]
                    [ mainSvg
                    , Svg.rect
                        [ width <| String.fromInt <| round <| toFloat w / model.svg.scale
                        , height <| String.fromInt <| round <| toFloat h / model.svg.scale
                        , x <| String.fromInt (0 - centerX)
                        , y <| String.fromInt (0 - centerY)
                        , stroke "#333333"
                        , strokeWidth "40"
                        , fill "transparent"
                        , class "display-rect"
                        ]
                        []
                    ]
                ]

          else
            svg [] []
        ]
