module Views.Diagram.ImpactMap exposing (view)

import List.Extra exposing (getAt, scanl1, zip3)
import Models.Diagram exposing (Model, Msg(..), Point, Settings)
import Models.Item as Item exposing (Item, ItemType(..))
import Svg exposing (Svg, g, line)
import Svg.Attributes exposing (stroke, strokeWidth, transform, x1, x2, y1, y2)
import Utils
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
            List.head model.items
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
                        ++ String.fromInt
                            (if isInfinite <| toFloat <| model.x then
                                10

                             else
                                model.x + 10
                            )
                        ++ ","
                        ++ String.fromInt
                            (if isInfinite <| toFloat <| model.y then
                                0

                             else
                                model.y + yCenter
                            )
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


nodesView : Settings -> Int -> ( Int, Int ) -> Maybe Item -> List Item -> Svg Msg
nodesView settings hierarchy ( x, y ) selectedItem items =
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
        offsetHeight =
            settings.size.height // 2

        offsetWidth =
            5

        ( fromPoint, toPoint ) =
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
