module Views.Diagram.MindMap exposing (view)

import Constants exposing (..)
import Html as Html exposing (div, img)
import Html.Attributes as Attr
import List.Extra exposing (getAt, scanl1, splitAt, zip3)
import Models.Diagram exposing (Model, Msg(..), Point, Settings)
import Models.Item as Item exposing (Item, ItemType(..))
import Svg exposing (Svg, foreignObject, g, line, rect, svg)
import Svg.Attributes exposing (..)
import Svg.Events exposing (onClick)
import Utils


type Direction
    = Left
    | Right


xMargin =
    100


yMargin =
    10


view : Model -> Svg Msg
view model =
    let
        rootItem =
            List.head model.items
    in
    case rootItem of
        Just root ->
            let
                items =
                    Item.unwrapChildren root.children

                itemsCount =
                    List.length items

                ( right, left ) =
                    splitAt (itemsCount // 2) items

                ( canvasWidth, canvasHeight ) =
                    Utils.getCanvasSize model

                ( xCenter, yCenter ) =
                    if model.matchParent then
                        ( canvasWidth // 2 - model.settings.size.width * 2
                        , canvasHeight // 2 - model.settings.size.height * 2
                        )

                    else
                        ( model.width // 2 - model.settings.size.width * 2
                        , model.height // 2 - model.settings.size.height * 2
                        )
            in
            g
                [ transform
                    ("translate("
                        ++ String.fromInt (model.x + xCenter)
                        ++ ","
                        ++ String.fromInt (model.y + yCenter)
                        ++ ")"
                    )
                ]
                [ nodesView model.settings 2 ( 0, 0 ) Left left
                , nodesView model.settings 2 ( 0, 0 ) Right right
                , nodeItemView model.settings
                    1
                    ( 0, 0 )
                    root
                ]

        Nothing ->
            g
                [ transform
                    ("translate("
                        ++ String.fromInt model.x
                        ++ ","
                        ++ String.fromInt model.y
                        ++ ")"
                    )
                ]
                []


nodesView : Settings -> Int -> ( Int, Int ) -> Direction -> List Item -> Svg Msg
nodesView settings hierarchy ( x, y ) direction items =
    let
        svgWidth =
            settings.size.width

        svgHeight =
            settings.size.height

        tmpNodeCounts =
            items
                |> List.map
                    (\i ->
                        if List.isEmpty (Item.unwrapChildren i.children) then
                            0

                        else
                            Item.getChildrenCount i
                    )
                |> List.concatMap
                    (\count ->
                        let
                            v =
                                round <| toFloat count / 2.0
                        in
                        [ v, v ]
                    )
                |> scanl1 (+)

        nodeCounts =
            tmpNodeCounts
                |> List.indexedMap (\i _ -> i)
                |> List.filter (\i -> i == 0 || modBy 2 i == 0)
                |> List.map (\i -> getAt i tmpNodeCounts |> Maybe.withDefault 1)
                |> List.indexedMap (\i v -> v + i + 1)

        yOffset =
            List.sum nodeCounts // List.length nodeCounts * svgHeight

        range =
            List.range 0 (List.length nodeCounts)
    in
    g []
        (zip3 range nodeCounts items
            |> List.concatMap
                (\( i, nodeCount, item ) ->
                    let
                        itemX =
                            if direction == Left then
                                x - (svgWidth + xMargin)

                            else
                                x + (svgWidth + xMargin)

                        itemY =
                            y + (nodeCount * svgHeight - yOffset) + (i * yMargin)
                    in
                    nodeLineView settings
                        direction
                        { x = x, y = y }
                        { x = itemX, y = itemY }
                        :: [ nodesView
                                settings
                                (hierarchy + 1)
                                ( itemX
                                , itemY
                                )
                                direction
                                (Item.unwrapChildren item.children)
                           , nodeItemView settings
                                hierarchy
                                ( itemX, itemY )
                                item
                           ]
                )
        )


nodeLineView : Settings -> Direction -> Point -> Point -> Svg Msg
nodeLineView settings direction fromBase toBase =
    let
        offsetHeight =
            settings.size.height // 2

        offsetWidth =
            5

        ( fromPoint, toPoint ) =
            case direction of
                Left ->
                    ( { x = fromBase.x + offsetWidth, y = fromBase.y + offsetHeight }
                    , { x = toBase.x + settings.size.width - offsetWidth, y = toBase.y + offsetHeight }
                    )

                Right ->
                    ( { x = fromBase.x + settings.size.width - offsetWidth, y = fromBase.y + offsetHeight }
                    , { x = toBase.x + offsetWidth, y = toBase.y + offsetHeight }
                    )
    in
    line
        [ x1 <| String.fromInt fromPoint.x
        , y1 <| String.fromInt fromPoint.y
        , x2 <| String.fromInt toPoint.x
        , y2 <| String.fromInt toPoint.y
        , stroke settings.color.line
        , strokeWidth "1.3"
        ]
        []


getColor : Settings -> Int -> ( String, String )
getColor settings hierarchy =
    case hierarchy of
        1 ->
            ( settings.color.activity.color, settings.color.activity.backgroundColor )

        2 ->
            ( settings.color.task.color, settings.color.task.backgroundColor )

        _ ->
            ( settings.color.story.color, settings.color.story.backgroundColor )


nodeItemView : Settings -> Int -> ( Int, Int ) -> Item -> Svg Msg
nodeItemView settings hierarchy ( posX, posY ) item =
    let
        svgWidth =
            String.fromInt settings.size.width

        svgHeight =
            String.fromInt settings.size.height

        ( colour, backgroundColor ) =
            getColor settings hierarchy
    in
    svg
        [ width svgWidth
        , height svgHeight
        , x (String.fromInt posX)
        , y (String.fromInt posY)
        , onClick (ItemClick item)
        ]
        [ rect
            [ width svgWidth
            , height svgHeight
            , fill backgroundColor
            , stroke "rgba(192,192,192,0.5)"
            , rx "10"
            , ry "10"
            ]
            []
        , foreignObject
            [ width svgWidth
            , height svgHeight
            , fill backgroundColor
            , color colour
            , fontSize (item.text |> String.replace " " "" |> Utils.calcFontSize settings.size.width)
            , fontFamily settings.font
            , class "svg-text"
            ]
            [ if Utils.isImageUrl item.text then
                img
                    [ Attr.style "object-fit" "cover"
                    , Attr.style "width" (String.fromInt settings.size.width)
                    , Attr.src item.text
                    ]
                    []

              else
                div
                    [ Attr.style "padding" "8px"
                    , Attr.style "font-family" ("'" ++ settings.font ++ "', sans-serif")
                    , Attr.style "word-wrap" "break-word"
                    ]
                    [ Html.text item.text ]
            ]
        ]
