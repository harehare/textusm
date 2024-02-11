module Diagram.SiteMap.View exposing (docs, view)

import Constants
import Diagram.Types exposing (Diagram, SelectedItem, SelectedItemInfo)
import Diagram.Types.CardSize as CardSize
import Diagram.Types.Data as DiagramData
import Diagram.Types.Settings as DiagramSettings
import Diagram.Types.Type as DiagramType
import Diagram.View.Card as Card
import Diagram.View.Views as View
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter exposing (Chapter)
import List.Extra as ListEx
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Attributes as SvgAttr
import Svg.Styled.Lazy as Lazy
import Types.Color as Color
import Types.Item as Item exposing (Item, Items)
import Types.Position as Position exposing (Position)
import Types.Property as Property exposing (Property)


view :
    { items : Items
    , data : DiagramData.Data
    , settings : DiagramSettings.Settings
    , selectedItem : SelectedItem
    , diagram : Diagram
    , property : Property
    , onEditSelectedItem : String -> msg
    , onEndEditSelectedItem : Item -> msg
    , onSelect : Maybe SelectedItemInfo -> msg
    , dragStart : View.DragStart msg
    }
    -> Svg msg
view { items, settings, property, selectedItem, onEditSelectedItem, onEndEditSelectedItem, onSelect, dragStart } =
    let
        rootItem : Maybe Item
        rootItem =
            Item.head items
    in
    case rootItem of
        Just root ->
            let
                rootItems : Items
                rootItems =
                    Item.unwrapChildren <| Item.getChildren root
            in
            Svg.g
                []
                [ siteView
                    { settings = settings
                    , property = property
                    , position = ( 0, Constants.itemSpan + CardSize.toInt settings.size.height )
                    , selectedItem = selectedItem
                    , items = rootItems
                    , onEditSelectedItem = onEditSelectedItem
                    , onEndEditSelectedItem = onEndEditSelectedItem
                    , onSelect = onSelect
                    , dragStart = dragStart
                    }
                , Lazy.lazy Card.viewWithDefaultColor
                    { settings = settings
                    , property = property
                    , position = ( 0, 0 )
                    , selectedItem = selectedItem
                    , item = root
                    , canMove = True
                    , onEditSelectedItem = onEditSelectedItem
                    , onEndEditSelectedItem = onEndEditSelectedItem
                    , onSelect = onSelect
                    , dragStart = dragStart
                    }
                ]

        Nothing ->
            Svg.g [] []


siteLineView : DiagramSettings.Settings -> Position -> Position -> Svg msg
siteLineView settings ( xx1, yy1 ) ( xx2, yy2 ) =
    let
        centerX : Int
        centerX =
            CardSize.toInt settings.size.width // 2
    in
    if xx1 == xx2 then
        Svg.line
            [ SvgAttr.x1 <| String.fromInt <| xx1 + centerX
            , SvgAttr.y1 <| String.fromInt yy1
            , SvgAttr.x2 <| String.fromInt <| xx2 + centerX
            , SvgAttr.y2 <| String.fromInt yy2
            , SvgAttr.stroke <| Color.toString settings.color.line
            , SvgAttr.strokeWidth "1"
            ]
            []

    else
        Svg.g []
            [ Svg.line
                [ SvgAttr.x1 <| String.fromInt <| xx1 + centerX
                , SvgAttr.y1 <| String.fromInt <| yy1 + CardSize.toInt settings.size.height + Constants.itemSpan // 2
                , SvgAttr.x2 <| String.fromInt <| xx2 + centerX
                , SvgAttr.y2 <| String.fromInt <| yy1 + CardSize.toInt settings.size.height + Constants.itemSpan // 2
                , SvgAttr.stroke <| Color.toString settings.color.line
                , SvgAttr.strokeWidth "1"
                ]
                []
            , Svg.line
                [ SvgAttr.x1 <| String.fromInt <| xx2 + centerX
                , SvgAttr.y1 <| String.fromInt <| yy1 + CardSize.toInt settings.size.height + Constants.itemSpan // 2
                , SvgAttr.x2 <| String.fromInt <| xx2 + centerX
                , SvgAttr.y2 <| String.fromInt <| yy2
                , SvgAttr.stroke <| Color.toString settings.color.line
                , SvgAttr.strokeWidth "1"
                ]
                []
            ]


siteTreeLineView : DiagramSettings.Settings -> Position -> Position -> Svg msg
siteTreeLineView settings ( xx1, yy1 ) ( xx2, yy2 ) =
    let
        itemPadding : Int
        itemPadding =
            Constants.itemSpan // 2
    in
    Svg.g []
        [ Svg.line
            [ SvgAttr.x1 <| String.fromInt <| xx1 + itemPadding
            , SvgAttr.y1 <| String.fromInt <| yy1
            , SvgAttr.x2 <| String.fromInt <| xx1 + itemPadding
            , SvgAttr.y2 <| String.fromInt <| yy2 + CardSize.toInt settings.size.height // 2
            , SvgAttr.stroke <| Color.toString settings.color.line
            , SvgAttr.strokeWidth "1"
            ]
            []
        , Svg.line
            [ SvgAttr.x1 <| String.fromInt <| xx1 + itemPadding
            , SvgAttr.y1 <| String.fromInt <| yy2 + CardSize.toInt settings.size.height // 2
            , SvgAttr.x2 <| String.fromInt <| xx2 + CardSize.toInt settings.size.width
            , SvgAttr.y2 <| String.fromInt <| yy2 + CardSize.toInt settings.size.height // 2
            , SvgAttr.stroke <| Color.toString settings.color.line
            , SvgAttr.strokeWidth "1"
            ]
            []
        ]


siteTreeView :
    { settings : DiagramSettings.Settings
    , property : Property
    , position : Position
    , selectedItem : SelectedItem
    , items : Items
    , onEditSelectedItem : String -> msg
    , onEndEditSelectedItem : Item -> msg
    , onSelect : Maybe SelectedItemInfo -> msg
    , dragStart : View.DragStart msg
    }
    -> Svg msg
siteTreeView { settings, property, position, selectedItem, items, onEditSelectedItem, onEndEditSelectedItem, onSelect, dragStart } =
    let
        childrenCountList : List Int
        childrenCountList =
            0
                :: (items
                        |> Item.map
                            (\i ->
                                if Item.isEmpty (Item.unwrapChildren <| Item.getChildren i) then
                                    0

                                else
                                    Item.getChildrenCount i
                            )
                        |> ListEx.scanl1 (+)
                   )
    in
    Svg.g []
        (ListEx.zip childrenCountList (Item.unwrap items)
            |> List.indexedMap
                (\i ( childrenCount, item ) ->
                    let
                        children : Items
                        children =
                            Item.unwrapChildren <| Item.getChildren item

                        x : Int
                        x =
                            Position.getX position + Constants.itemSpan

                        y : Int
                        y =
                            Position.getY position + i * (CardSize.toInt settings.size.height + Constants.itemSpan) + childrenCount * (CardSize.toInt settings.size.height + Constants.itemSpan)
                    in
                    [ siteTreeLineView settings (Tuple.mapSecond (\y_ -> y_ - Constants.itemSpan) position) ( Position.getX position, y )
                    , Card.viewWithDefaultColor
                        { settings = settings
                        , property = property
                        , position = ( x, y )
                        , selectedItem = selectedItem
                        , item = item
                        , canMove = True
                        , onEditSelectedItem = onEditSelectedItem
                        , onEndEditSelectedItem = onEndEditSelectedItem
                        , onSelect = onSelect
                        , dragStart = dragStart
                        }
                    , siteTreeView
                        { settings = settings
                        , property = property
                        , position =
                            ( x
                            , y + (CardSize.toInt settings.size.height + Constants.itemSpan)
                            )
                        , selectedItem = selectedItem
                        , items = children
                        , onEditSelectedItem = onEditSelectedItem
                        , onEndEditSelectedItem = onEndEditSelectedItem
                        , onSelect = onSelect
                        , dragStart = dragStart
                        }
                    ]
                )
            |> List.concat
        )


siteView :
    { settings : DiagramSettings.Settings
    , property : Property
    , position : Position
    , selectedItem : SelectedItem
    , items : Items
    , onEditSelectedItem : String -> msg
    , onEndEditSelectedItem : Item -> msg
    , onSelect : Maybe SelectedItemInfo -> msg
    , dragStart : View.DragStart msg
    }
    -> Svg msg
siteView { settings, property, position, selectedItem, items, onEditSelectedItem, onEndEditSelectedItem, onSelect, dragStart } =
    let
        hierarchyCountList : List Int
        hierarchyCountList =
            0
                :: Item.map (\item -> Item.getHierarchyCount item - 1) items
                |> ListEx.scanl1 (+)
    in
    Svg.g []
        (ListEx.zip hierarchyCountList (Item.unwrap items)
            |> List.indexedMap
                (\i ( hierarchyCount, item ) ->
                    let
                        cardWidth : Int
                        cardWidth =
                            CardSize.toInt settings.size.width + Constants.itemSpan

                        children : Items
                        children =
                            Item.unwrapChildren <| Item.getChildren item

                        x : Int
                        x =
                            Position.getX position
                                + i
                                * (cardWidth + Constants.itemSpan)
                                + hierarchyCount
                                * Constants.itemSpan
                    in
                    [ Card.viewWithDefaultColor
                        { settings = settings
                        , property = property
                        , position = ( x, Position.getY position )
                        , selectedItem = selectedItem
                        , item = item
                        , canMove = True
                        , onEditSelectedItem = onEditSelectedItem
                        , onEndEditSelectedItem = onEndEditSelectedItem
                        , onSelect = onSelect
                        , dragStart = dragStart
                        }
                    , siteLineView settings ( 0, 0 ) ( x, Position.getY position )
                    , siteTreeView
                        { settings = settings
                        , property = property
                        , position =
                            ( x
                            , Position.getY position + CardSize.toInt settings.size.height + Constants.itemSpan
                            )
                        , selectedItem = selectedItem
                        , items = children
                        , onEditSelectedItem = onEditSelectedItem
                        , onEndEditSelectedItem = onEndEditSelectedItem
                        , onSelect = onSelect
                        , dragStart = dragStart
                        }
                    ]
                )
            |> List.concat
        )


docs : Chapter x
docs =
    Chapter.chapter "SiteMap"
        |> Chapter.renderComponent
            (Svg.svg
                [ SvgAttr.width "100%"
                , SvgAttr.height "100%"
                , SvgAttr.viewBox "0 0 2048 2048"
                ]
                [ view
                    { items = Item.empty
                    , data =
                        DiagramData.SiteMap
                            (DiagramType.defaultText DiagramType.SiteMap |> Item.fromString |> Tuple.second)
                            1
                    , settings = DiagramSettings.default
                    , diagram =
                        { size = ( 100, 100 )
                        , position = ( 0, 0 )
                        , isFullscreen = False
                        }
                    , selectedItem = Nothing
                    , property = Property.empty
                    , onEditSelectedItem = \_ -> Actions.logAction "onEditSelectedItem"
                    , onEndEditSelectedItem = \_ -> Actions.logAction "onEndEditSelectedItem"
                    , onSelect = \_ -> Actions.logAction "onEndEditSelectedItem"
                    , dragStart = \_ _ -> SvgAttr.style ""
                    }
                ]
                |> Svg.toUnstyled
            )
