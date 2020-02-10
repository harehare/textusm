module Views.Diagram.MindMap exposing (view)

import List.Extra exposing (getAt, scanl1, splitAt, zip3)
import Models.Diagram exposing (Model, Msg(..), Point, Settings)
import Models.Item as Item exposing (Item, ItemType(..))
import Svg exposing (Svg, g, line)
import Svg.Attributes exposing (stroke, strokeWidth, transform, x1, x2, y1, y2)
import Utils
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
                        ++ String.fromInt
                            (if isInfinite <| toFloat <| model.x then
                                0

                             else
                                model.x + xCenter
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
                [ nodesView model.settings 2 ( 0, 0 ) Left model.selectedItem left
                , nodesView model.settings 2 ( 0, 0 ) Right model.selectedItem right
                , Views.editableCardView model.settings
                    ( 0, 0 )
                    model.selectedItem
                    root
                ]

        Nothing ->
            g [] []


nodesView : Settings -> Int -> ( Int, Int ) -> Direction -> Maybe Item -> List Item -> Svg Msg
nodesView settings hierarchy ( x, y ) direction selectedItem items =
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
                    [ nodeLineView settings
                        direction
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
                    , Views.editableCardView settings
                        ( itemX, itemY )
                        selectedItem
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
