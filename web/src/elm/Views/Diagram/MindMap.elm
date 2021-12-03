module Views.Diagram.MindMap exposing (view)

import List.Extra as ListEx
import Models.Diagram as Diagram exposing (Model, Msg, SelectedItem, Settings)
import Models.Item as Item exposing (Item, Items)
import Models.ItemSettings as ItemSettings
import Models.Position as Position exposing (Position)
import Models.Size exposing (Size)
import Svg.Styled as Svg exposing (Svg)
import Views.Diagram.Path as Path
import Views.Diagram.Views as Views
import Views.Empty as Empty


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
    case model.data of
        Diagram.MindMap items _ ->
            let
                moveingItem =
                    Diagram.moveingItem model
            in
            case Item.head items of
                Just root ->
                    let
                        mindMapItems =
                            Item.unwrapChildren <| Item.getChildren root

                        itemsCount =
                            Item.length mindMapItems

                        ( right, left ) =
                            Item.splitAt (itemsCount // 2) mindMapItems

                        rootItem =
                            Maybe.map
                                (\m ->
                                    if Item.getLineNo m == Item.getLineNo root then
                                        m

                                    else
                                        root
                                )
                                moveingItem
                                |> Maybe.withDefault root
                    in
                    Svg.g
                        []
                        [ nodesView
                            { settings = model.settings
                            , hierarchy = 2
                            , position = Position.zero
                            , direction = Left
                            , selectedItem = model.selectedItem
                            , moveingItem = moveingItem
                            , items = left
                            }
                        , nodesView
                            { settings = model.settings
                            , hierarchy = 2
                            , position = Position.zero
                            , direction = Right
                            , selectedItem = model.selectedItem
                            , moveingItem = moveingItem
                            , items = right
                            }
                        , Views.rootTextNode
                            { settings = model.settings
                            , position = Position.zero
                            , selectedItem = model.selectedItem
                            , item = rootItem
                            }
                        ]

                Nothing ->
                    Svg.g [] []

        _ ->
            Empty.view


nodesView :
    { settings : Settings
    , hierarchy : Int
    , position : Position
    , direction : Direction
    , selectedItem : SelectedItem
    , moveingItem : Maybe Item
    , items : Items
    }
    -> Svg Msg
nodesView { settings, hierarchy, position, direction, selectedItem, items, moveingItem } =
    let
        svgWidth =
            settings.size.width

        svgHeight =
            settings.size.height

        ( x, y ) =
            position

        tmpNodeCounts =
            items
                |> Item.map
                    (\i ->
                        if Item.isEmpty (Item.unwrapChildren <| Item.getChildren i) then
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
                |> ListEx.scanl1 (+)

        nodeCounts =
            tmpNodeCounts
                |> List.indexedMap (\i _ -> i)
                |> List.filterMap
                    (\i ->
                        if i == 0 || modBy 2 i == 0 then
                            ListEx.getAt i tmpNodeCounts

                        else
                            Nothing
                    )
                |> List.indexedMap (\i v -> v + i + 1)

        yOffset =
            List.sum nodeCounts // List.length nodeCounts * svgHeight

        range =
            List.range 0 (List.length nodeCounts)
    in
    Svg.g []
        (ListEx.zip3 range nodeCounts (Item.unwrap items)
            |> List.concatMap
                (\( i, nodeCount, item ) ->
                    let
                        offset =
                            Maybe.map
                                (\m ->
                                    if Item.getLineNo m == Item.getLineNo item then
                                        m

                                    else
                                        item
                                )
                                moveingItem
                                |> Maybe.withDefault item
                                |> Item.getItemSettings
                                |> Maybe.map ItemSettings.getOffset
                                |> Maybe.withDefault Position.zero

                        itemX =
                            (if direction == Left then
                                x - (svgWidth + xMargin)

                             else
                                x + (svgWidth + xMargin)
                            )
                                + Position.getX offset

                        itemY =
                            y
                                + (nodeCount * svgHeight - yOffset)
                                + (i * yMargin)
                                + Position.getY offset
                    in
                    [ nodeLineView
                        ( settings.size.width, settings.size.height )
                        settings.color.task.backgroundColor
                        ( x, y )
                        ( itemX, itemY )
                    , nodesView
                        { settings = settings
                        , hierarchy = hierarchy + 1
                        , position =
                            ( itemX
                            , itemY
                            )
                        , direction = direction
                        , selectedItem = selectedItem
                        , moveingItem = moveingItem
                        , items = Item.unwrapChildren <| Item.getChildren item
                        }
                    , Views.node settings
                        ( itemX, itemY )
                        selectedItem
                        item
                    ]
                )
        )


nodeLineView : Size -> String -> Position -> Position -> Svg Msg
nodeLineView ( width, height ) colour fromBase toBase =
    let
        ( fromPoint, toPoint ) =
            ( Tuple.mapBoth toFloat toFloat fromBase, Tuple.mapBoth toFloat toFloat toBase )

        size =
            ( toFloat width, toFloat height )
    in
    Path.view colour
        ( fromPoint, size )
        ( toPoint, size )
