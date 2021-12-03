module Views.Diagram.MiniMap exposing (view)

import Constants
import Css
    exposing
        ( absolute
        , backgroundColor
        , border3
        , bottom
        , color
        , cursor
        , default
        , fill
        , hex
        , important
        , int
        , position
        , property
        , px
        , rgba
        , right
        , solid
        , transparent
        , width
        , zIndex
        , zero
        )
import Css.Global exposing (children, class, each, typeSelector)
import Css.Transitions as Transitions
import Events
import Graphql.Enum.Diagram exposing (Diagram(..))
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes as Attr exposing (css)
import Models.Color as Color
import Models.Diagram as DiagramModel exposing (Msg)
import Models.Position as Position exposing (Position)
import Models.Size as Size exposing (Size)
import Style.Style as Style
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Attributes as SvgAttr


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
        [ css
            [ Css.position absolute
            , width <| px 260
            , backgroundColor <| hex "#ffffff"
            , zIndex <| int 1
            , cursor default
            , Style.roundedSm
            , bottom <| px 16
            , right <| px 16
            , Transitions.transition [ Transitions.height3 0.15 0.15 Transitions.easeOut ]
            , if showMiniMap then
                Css.batch [ Css.height <| px 150, border3 (px 1) solid (rgba 0 0 0 0.1) ]

              else
                Css.batch [ Css.height zero ]
            , children
                [ each [ class "ts-card", class "ts-text", class "ts-canvas", class "ts-node", class "ts-grid" ]
                    [ important <| fill <| rgba 72 169 221 0.2
                    , important <| property "stroke" "#48a9dd"
                    , important <| property "stroke-width" "8px"
                    ]
                , each [ typeSelector "line", typeSelector "text" ]
                    [ important <| color transparent
                    , important <| fill transparent
                    ]
                ]
            ]
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
