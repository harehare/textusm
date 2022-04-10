module Views.Diagram.MindMap exposing (view)

import Html.Attributes exposing (property)
import List.Extra as ListEx
import Models.Diagram as Diagram exposing (Model, Msg, SelectedItem)
import Models.DiagramData as DiagramData
import Models.DiagramSettings as DiagramSettings
import Models.Item as Item exposing (Item, Items)
import Models.ItemSettings as ItemSettings
import Models.Position as Position exposing (Position)
import Models.Property exposing (Property)
import Models.Size exposing (Size)
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Lazy as Lazy
import Views.Diagram.Path as Path
import Views.Diagram.TextNode as TextNode
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
        DiagramData.MindMap items _ ->
            case Item.head items of
                Just root ->
                    let
                        moveingItem : Maybe Item
                        moveingItem =
                            Diagram.moveingItem model

                        mindMapItems : Items
                        mindMapItems =
                            Item.unwrapChildren <| Item.getChildren root

                        itemsCount : Int
                        itemsCount =
                            Item.length mindMapItems

                        ( right, left ) =
                            Item.splitAt (itemsCount // 2) mindMapItems

                        rootItem : Item
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
                            , property = model.property
                            , hierarchy = 2
                            , position = Position.zero
                            , direction = Left
                            , selectedItem = model.selectedItem
                            , moveingItem = moveingItem
                            , items = left
                            }
                        , nodesView
                            { settings = model.settings
                            , property = model.property
                            , hierarchy = 2
                            , position = Position.zero
                            , direction = Right
                            , selectedItem = model.selectedItem
                            , moveingItem = moveingItem
                            , items = right
                            }
                        , TextNode.root
                            { settings = model.settings
                            , property = model.property
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
    { settings : DiagramSettings.Settings
    , property : Property
    , hierarchy : Int
    , position : Position
    , direction : Direction
    , selectedItem : SelectedItem
    , moveingItem : Maybe Item
    , items : Items
    }
    -> Svg Msg
nodesView { settings, property, hierarchy, position, direction, selectedItem, items, moveingItem } =
    let
        svgWidth : Int
        svgWidth =
            settings.size.width

        svgHeight : Int
        svgHeight =
            settings.size.height

        ( x, y ) =
            position

        tmpNodeCounts : List Int
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
                            v : Int
                            v =
                                round <| toFloat count / 2.0
                        in
                        [ v, v ]
                    )
                |> ListEx.scanl1 (+)

        nodeCounts : List Int
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

        yOffset : Int
        yOffset =
            List.sum nodeCounts // List.length nodeCounts * svgHeight

        range : List Int
        range =
            List.range 0 (List.length nodeCounts)
    in
    Svg.g []
        (ListEx.zip3 range nodeCounts (Item.unwrap items)
            |> List.concatMap
                (\( i, nodeCount, item ) ->
                    let
                        offset : Position
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

                        itemX : Int
                        itemX =
                            if direction == Left then
                                x - (svgWidth + xMargin)

                            else
                                x + (svgWidth + xMargin)

                        itemY : Int
                        itemY =
                            y + (nodeCount * svgHeight - yOffset) + (i * yMargin)
                    in
                    [ Lazy.lazy4 nodeLineView
                        ( settings.size.width, settings.size.height )
                        settings.color.task.backgroundColor
                        ( x, y )
                        ( itemX + Position.getX offset, itemY + Position.getY offset )
                    , Lazy.lazy nodesView
                        { settings = settings
                        , property = property
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
                    , Lazy.lazy5 TextNode.view
                        settings
                        property
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

        size : ( Float, Float )
        size =
            ( toFloat width, toFloat height )
    in
    Path.view colour
        ( fromPoint, size )
        ( toPoint, size )
