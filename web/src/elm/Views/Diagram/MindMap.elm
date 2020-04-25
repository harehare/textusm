module Views.Diagram.MindMap exposing (view)

import Data.Item as Item exposing (Item, ItemType(..), Items)
import Data.Position exposing (Position)
import List.Extra exposing (getAt, scanl1, splitAt, zip3)
import Models.Diagram exposing (Model, Msg(..), Point, Settings)
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
                        ( toFloat canvasWidth / 2 - toFloat model.settings.size.width * 2
                        , toFloat canvasHeight / 2 - toFloat model.settings.size.height * 2
                        )

                    else
                        ( toFloat model.width / 2 - toFloat model.settings.size.width * 2
                        , toFloat model.height / 2 - toFloat model.settings.size.height * 2
                        )
            in
            g
                [ transform
                    ("translate("
                        ++ String.fromFloat
                            (if isInfinite <| model.x then
                                0

                             else
                                model.x + xCenter
                            )
                        ++ ","
                        ++ String.fromFloat
                            (if isInfinite <| model.y then
                                0

                             else
                                model.y + yCenter
                            )
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
                        { x = x, y = y }
                        { x = itemX, y = itemY }
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


nodeLineView : Settings -> Point -> Point -> Svg Msg
nodeLineView settings fromBase toBase =
    let
        ( fromPoint, toPoint ) =
            ( ( toFloat <| fromBase.x
              , toFloat <| fromBase.y
              )
            , ( toFloat <| toBase.x
              , toFloat <| toBase.y
              )
            )

        size =
            ( toFloat settings.size.width, toFloat settings.size.height )
    in
    Path.view settings
        ( fromPoint, size )
        ( toPoint, size )
