module Views.Diagram.ImpactMap exposing (view)

import Data.Item as Item exposing (Item, ItemType(..), Items)
import Data.Position as Position exposing (Position)
import List.Extra exposing (getAt, scanl1, zip3)
import Models.Diagram exposing (Model, Msg(..), Settings)
import Svg exposing (Svg, g)
import Svg.Attributes exposing (transform)
import Utils
import Views.Diagram.Path as Path
import Views.Diagram.Views as Views


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

                ( _, canvasHeight ) =
                    Utils.getCanvasSize model

                yCenter =
                    canvasHeight // 2
            in
            g
                [ transform
                    ("translate("
                        ++ String.fromInt (Position.getX model.position + 10)
                        ++ ","
                        ++ String.fromInt (Position.getY model.position + yCenter)
                        ++ ")"
                    )
                ]
                [ nodesView model.settings 2 ( 0, 0 ) model.selectedItem items
                , Views.cardView model.settings
                    ( 0, 0 )
                    model.selectedItem
                    root
                ]

        Nothing ->
            g [] []


nodesView : Settings -> Int -> Position -> Maybe Item -> Items -> Svg Msg
nodesView settings hierarchy ( x, y ) selectedItem items =
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
