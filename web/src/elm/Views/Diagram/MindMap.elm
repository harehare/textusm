module Views.Diagram.MindMap exposing (view)

import Data.Item as Item exposing (Item, ItemType(..), Items)
import Data.Position as Position exposing (Position)
import Data.Size as Size
import List.Extra exposing (getAt, scanl1, splitAt, zip3)
import Models.Diagram exposing (Model, Msg(..), Settings)
import Svg exposing (Svg, g)
import Svg.Attributes exposing (transform)
import Utils
import Views.Diagram.Path as Path
import Views.Diagram.Views as Views


type Direction
    = Left
    | Right


xMargin : Int
xMargin =
    100


yMargin : Int
yMargin =
    10


view : Model -> Svg Msg
view model =
    let
        rootItem =
            Item.head model.items
    in
    case rootItem of
        Just root ->
            let
                items =
                    Item.unwrapChildren root.children

                itemsCount =
                    Item.length items

                ( right, left ) =
                    Item.splitAt (itemsCount // 2) items

                ( canvasWidth, canvasHeight ) =
                    Utils.getCanvasSize model

                ( xCenter, yCenter ) =
                    if model.matchParent then
                        ( canvasWidth // 2 - model.settings.size.width * 2
                        , canvasHeight // 2 - model.settings.size.height * 2
                        )

                    else
                        ( Size.getWidth model.size // 2 - model.settings.size.width * 2
                        , Size.getHeight model.size // 2 - model.settings.size.height * 2
                        )
            in
            g
                [ transform
                    ("translate("
                        ++ String.fromInt (Position.getX model.position + xCenter)
                        ++ ","
                        ++ String.fromInt (Position.getY model.position + yCenter)
                        ++ ")"
                    )
                ]
                [ nodesView model.settings 2 ( 0, 0 ) Left model.selectedItem left
                , nodesView model.settings 2 ( 0, 0 ) Right model.selectedItem right
                , Views.cardView model.settings
                    ( 0, 0 )
                    model.selectedItem
                    root
                ]

        Nothing ->
            g [] []


nodesView : Settings -> Int -> Position -> Direction -> Maybe Item -> Items -> Svg Msg
nodesView settings hierarchy ( x, y ) direction selectedItem items =
    let
        svgWidth =
            settings.size.width

        svgHeight =
            settings.size.height

        tmpNodeCounts =
            items
                |> Item.map
                    (\i ->
                        if Item.isEmpty (Item.unwrapChildren i.children) then
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
        (zip3 range nodeCounts (Item.unwrap items)
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
                    [ nodeLineView settings
                        ( x, y )
                        ( itemX, itemY )
                    , nodesView
                        settings
                        (hierarchy + 1)
                        ( itemX
                        , itemY
                        )
                        direction
                        selectedItem
                        (Item.unwrapChildren item.children)
                    , Views.cardView settings
                        ( itemX, itemY )
                        selectedItem
                        item
                    ]
                )
        )


nodeLineView : Settings -> Position -> Position -> Svg Msg
nodeLineView settings fromBase toBase =
    let
        ( fromPoint, toPoint ) =
            ( Tuple.mapBoth toFloat toFloat fromBase, Tuple.mapBoth toFloat toFloat toBase )

        size =
            ( toFloat settings.size.width, toFloat settings.size.height )
    in
    Path.view settings
        ( fromPoint, size )
        ( toPoint, size )
