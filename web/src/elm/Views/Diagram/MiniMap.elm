module Views.Diagram.MiniMap exposing (view)

import Constants
import Events
import Graphql.Enum.Diagram exposing (Diagram(..))
import Html exposing (Html)
import Html.Attributes as Attr
import Models.Color as Color
import Models.Diagram as DiagramModel exposing (Msg)
import Models.Position as Position exposing (Position)
import Models.Size as Size exposing (Size)
import Svg exposing (Svg)
import Svg.Attributes as SvgAttr


view :
    { showMiniMap : Bool
    , diagramType : Diagram
    , scale : Float
    , position : Position
    , svgSize : Size
    , viewport : Size
    , diagramSvg : Svg Msg
    , moveState : DiagramModel.MoveState
    }
    -> Html Msg
view { showMiniMap, diagramType, scale, position, svgSize, viewport, diagramSvg, moveState } =
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
    Html.div
        ([ Attr.class "mini-map"
         , Attr.style "position" "absolute"
         , Attr.style "width" "260px"
         , Attr.style "background-color" "#fff"
         , Attr.style "z-index" "1"
         , Attr.style "cursor" "default"
         , Attr.style "border-radius" "4px"
         , Attr.style "bottom" "16px"
         , Attr.style "right" "16px"
         , Attr.style "transition" "height 0.15s ease-out"
         , case moveState of
            DiagramModel.MiniMapMove ->
                Events.onMouseMove <|
                    \event ->
                        let
                            ( x, y ) =
                                event.pagePos
                        in
                        DiagramModel.Move ( round x, round y )

            _ ->
                Attr.style "" ""
         ]
            ++ (if showMiniMap then
                    [ Attr.style "height" "150px", Attr.style "border" "1px solid rgba(0, 0, 0, 0.1)" ]

                else
                    [ Attr.style "height" "0px" ]
               )
        )
        [ if showMiniMap then
            Svg.svg
                [ SvgAttr.width "270"
                , SvgAttr.height "150"
                , SvgAttr.viewBox "0 0 2880 1620"
                ]
                [ Svg.g
                    [ SvgAttr.transform <|
                        "translate("
                            ++ String.fromInt (Position.getX startPosition)
                            ++ ","
                            ++ String.fromInt (Position.getY startPosition)
                            ++ "), scale(0.5)"
                    ]
                    [ diagramSvg
                    , Svg.rect
                        [ SvgAttr.width <| String.fromInt <| round <| (toFloat <| Size.getWidth viewport) / scale
                        , SvgAttr.height <| String.fromInt <| round <| (toFloat <| Size.getHeight viewport) / scale
                        , SvgAttr.x <| String.fromInt <| 0 - Position.getX position
                        , SvgAttr.y <| String.fromInt <| 0 - Position.getY position
                        , SvgAttr.stroke <| Color.toString Color.gray
                        , SvgAttr.strokeWidth "40"
                        , SvgAttr.fill "transparent"
                        , SvgAttr.class "display-rect"
                        , case moveState of
                            DiagramModel.MiniMapMove ->
                                Attr.style "cursor" "grabbing"

                            _ ->
                                Attr.style "cursor" "grab"
                        , Events.onMouseDown <|
                            \event ->
                                let
                                    ( x, y ) =
                                        event.pagePos
                                in
                                DiagramModel.Start DiagramModel.MiniMapMove ( round x, round y )
                        , Events.onWheel <| DiagramModel.chooseZoom 0.05
                        ]
                        []
                    ]
                ]

          else
            Svg.svg [] []
        ]
