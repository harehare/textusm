module Diagram.MindMap.View exposing (ViewType(..), docs, view)

import Diagram.Types as Diagram exposing (Diagram, MoveState, SelectedItem, SelectedItemInfo)
import Diagram.Types.CardSize as CardSize
import Diagram.Types.Data as DiagramData
import Diagram.Types.Settings as DiagramSettings
import Diagram.Types.Type as DiagramType
import Diagram.View.Path as Path
import Diagram.View.TextNode as TextNode
import Diagram.View.Views as View
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter exposing (Chapter)
import List.Extra as ListEx
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Attributes as SvgAttr
import Svg.Styled.Lazy as Lazy
import Types.Color exposing (Color)
import Types.Item as Item exposing (Item, Items)
import Types.Item.Settings as ItemSettings
import Types.Position as Position exposing (Position)
import Types.Property as Property exposing (Property)
import Types.Size exposing (Size)
import View.Empty as Empty


type ViewType
    = MindMap
    | ImpactMap


type Direction
    = Left
    | Right


xMargin : Int
xMargin =
    100


yMargin : Int
yMargin =
    10


view :
    { data : DiagramData.Data
    , settings : DiagramSettings.Settings
    , selectedItem : SelectedItem
    , diagram : Diagram
    , property : Property
    , viewType : ViewType
    , moveState : MoveState
    , onEditSelectedItem : String -> msg
    , onEndEditSelectedItem : Item -> msg
    , onSelect : Maybe SelectedItemInfo -> msg
    , dragStart : View.DragStart msg
    }
    -> Svg msg
view { data, settings, property, selectedItem, moveState, viewType, onEditSelectedItem, onEndEditSelectedItem, onSelect, dragStart } =
    case data of
        DiagramData.MindMap items _ ->
            case Item.head items of
                Just root ->
                    let
                        itemsCount : Int
                        itemsCount =
                            Item.length mindMapItems

                        ( right, left ) =
                            Item.splitAt (itemsCount // 2) mindMapItems

                        mindMapItems : Items
                        mindMapItems =
                            Item.unwrapChildren <| Item.getChildren root

                        moveingItem : Maybe Item
                        moveingItem =
                            Diagram.moveingItem moveState

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
                    case viewType of
                        MindMap ->
                            Svg.g
                                []
                                [ nodesView
                                    { settings = settings
                                    , property = property
                                    , hierarchy = 2
                                    , position = Position.zero
                                    , direction = Left
                                    , selectedItem = selectedItem
                                    , moveingItem = moveingItem
                                    , items = left
                                    , onEditSelectedItem = onEditSelectedItem
                                    , onEndEditSelectedItem = onEndEditSelectedItem
                                    , onSelect = onSelect
                                    , dragStart = dragStart
                                    }
                                , nodesView
                                    { settings = settings
                                    , property = property
                                    , hierarchy = 2
                                    , position = Position.zero
                                    , direction = Right
                                    , selectedItem = selectedItem
                                    , moveingItem = moveingItem
                                    , items = right
                                    , onEditSelectedItem = onEditSelectedItem
                                    , onEndEditSelectedItem = onEndEditSelectedItem
                                    , onSelect = onSelect
                                    , dragStart = dragStart
                                    }
                                , TextNode.root
                                    { settings = settings
                                    , property = property
                                    , position = Position.zero
                                    , selectedItem = selectedItem
                                    , item = rootItem
                                    , onEditSelectedItem = onEditSelectedItem
                                    , onEndEditSelectedItem = onEndEditSelectedItem
                                    , onSelect = onSelect
                                    }
                                ]

                        ImpactMap ->
                            Svg.g
                                []
                                [ nodesView
                                    { settings = settings
                                    , property = property
                                    , hierarchy = 2
                                    , position = Position.zero
                                    , direction = Right
                                    , selectedItem = selectedItem
                                    , moveingItem = moveingItem
                                    , items = mindMapItems
                                    , onEditSelectedItem = onEditSelectedItem
                                    , onEndEditSelectedItem = onEndEditSelectedItem
                                    , onSelect = onSelect
                                    , dragStart = dragStart
                                    }
                                , TextNode.root
                                    { settings = settings
                                    , property = property
                                    , position = Position.zero
                                    , selectedItem = selectedItem
                                    , item = rootItem
                                    , onEditSelectedItem = onEditSelectedItem
                                    , onEndEditSelectedItem = onEndEditSelectedItem
                                    , onSelect = onSelect
                                    }
                                ]

                Nothing ->
                    Svg.g [] []

        _ ->
            Empty.view


nodeLineView : Size -> Color -> Position -> Position -> Svg msg
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


nodesView :
    { settings : DiagramSettings.Settings
    , property : Property
    , hierarchy : Int
    , position : Position
    , direction : Direction
    , selectedItem : SelectedItem
    , moveingItem : Maybe Item
    , items : Items
    , onEditSelectedItem : String -> msg
    , onEndEditSelectedItem : Item -> msg
    , onSelect : Maybe SelectedItemInfo -> msg
    , dragStart : View.DragStart msg
    }
    -> Svg msg
nodesView { settings, property, hierarchy, position, direction, selectedItem, items, moveingItem, onEditSelectedItem, onEndEditSelectedItem, onSelect, dragStart } =
    let
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

        range : List Int
        range =
            List.range 0 (List.length nodeCounts)

        svgHeight : Int
        svgHeight =
            CardSize.toInt settings.size.height

        svgWidth : Int
        svgWidth =
            CardSize.toInt settings.size.width

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

        ( x, y ) =
            position

        yOffset : Int
        yOffset =
            List.sum nodeCounts // List.length nodeCounts * svgHeight
    in
    Svg.g []
        (ListEx.zip3 range nodeCounts (Item.unwrap items)
            |> List.concatMap
                (\( i, nodeCount, item ) ->
                    let
                        itemX : Int
                        itemX =
                            if direction == Left then
                                x - (svgWidth + xMargin)

                            else
                                x + (svgWidth + xMargin)

                        itemY : Int
                        itemY =
                            y + (nodeCount * svgHeight - yOffset) + (i * yMargin)

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
                                |> Item.getSettings
                                |> Maybe.map ItemSettings.getOffset
                                |> Maybe.withDefault Position.zero
                    in
                    [ Lazy.lazy4 nodeLineView
                        ( CardSize.toInt settings.size.width, CardSize.toInt settings.size.height )
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
                        , onEditSelectedItem = onEditSelectedItem
                        , onEndEditSelectedItem = onEndEditSelectedItem
                        , onSelect = onSelect
                        , dragStart = dragStart
                        }
                    , Lazy.lazy TextNode.view
                        { settings = settings
                        , property = property
                        , position = ( itemX, itemY )
                        , selectedItem = selectedItem
                        , item = item
                        , onEditSelectedItem = onEditSelectedItem
                        , onEndEditSelectedItem = onEndEditSelectedItem
                        , onSelect = onSelect
                        , dragStart = dragStart
                        }
                    ]
                )
        )


docs : Chapter x
docs =
    Chapter.chapter "MindMap"
        |> Chapter.renderComponent
            (Svg.svg
                [ SvgAttr.width "100%"
                , SvgAttr.height "100%"
                , SvgAttr.viewBox "0 0 2048 2048"
                ]
                [ view
                    { data =
                        DiagramData.MindMap
                            (DiagramType.defaultText DiagramType.MindMap |> Item.fromString |> Tuple.second)
                            1
                    , settings = DiagramSettings.default
                    , selectedItem = Nothing
                    , property = Property.empty
                    , moveState = Diagram.NotMove
                    , diagram =
                        { size = ( 100, 100 )
                        , position = ( 0, 0 )
                        , isFullscreen = False
                        }
                    , viewType = MindMap
                    , onEditSelectedItem = \_ -> Actions.logAction "onEditSelectedItem"
                    , onEndEditSelectedItem = \_ -> Actions.logAction "onEndEditSelectedItem"
                    , onSelect = \_ -> Actions.logAction "onEndEditSelectedItem"
                    , dragStart = \_ _ -> SvgAttr.style ""
                    }
                ]
                |> Svg.toUnstyled
            )
