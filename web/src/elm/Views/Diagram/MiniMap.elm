module Views.Diagram.MiniMap exposing (..)

import Constants
import Data.Position as Position exposing (Position)
import Data.Size as Size exposing (Size)
import Html exposing (Html, div)
import Html.Attributes as Attr
import Models.Diagram exposing (Msg(..))
import Models.Views.FourLs exposing (FourLsItem(..))
import Svg exposing (Svg, svg)
import Svg.Attributes exposing (class, fill, height, stroke, strokeWidth, transform, viewBox, width, x, y)
import TextUSM.Enum.Diagram exposing (Diagram(..))


view :
    { showMiniMap : Bool
    , diagramType : Diagram
    , scale : Float
    , position : Position
    , svgSize : Size
    , viewport : Size
    , diagramSvg : Svg Msg
    }
    -> Html Msg
view { showMiniMap, diagramType, scale, position, svgSize, viewport, diagramSvg } =
    let
        startPosition =
            case diagramType of
                MindMap ->
                    ( Size.getWidth svgSize // 3, Size.getHeight svgSize // 3 )

                ImpactMap ->
                    ( Constants.itemMargin, Size.getHeight svgSize // 3 )

                _ ->
                    Size.zero
    in
    div
        [ Attr.class "mini-map"
        , Attr.style "position" "absolute"
        , Attr.style "width" "260px"
        , if showMiniMap then
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
        , Attr.style "pointer-events" "none"
        ]
        [ if showMiniMap then
            svg
                [ width "270"
                , height "150"
                , viewBox "0 0 2880 1620"
                ]
                [ Svg.g
                    [ transform <|
                        "translate("
                            ++ String.fromInt (Position.getX startPosition)
                            ++ ","
                            ++ String.fromInt (Position.getY startPosition)
                            ++ "), scale(0.5)"
                    ]
                    [ diagramSvg
                    , Svg.rect
                        [ width <| String.fromInt <| round <| (toFloat <| Size.getWidth viewport) / scale
                        , height <| String.fromInt <| round <| (toFloat <| Size.getHeight viewport) / scale
                        , x <| String.fromInt <| 0 - Position.getX position
                        , y <| String.fromInt <| 0 - Position.getY position
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
