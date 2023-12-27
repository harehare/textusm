module Views.Diagram.Line exposing (horizontal, vertical)

import Events
import Models.Color as Color exposing (Color)
import Models.Diagram as Diagram exposing (ResizeDirection(..), SelectedItem, SelectedItemInfo)
import Models.Diagram.CardSize as CardSize
import Models.Diagram.Settings as DiagramSettings
import Models.Item as Item exposing (Item)
import Models.Item.Settings as ItemSettings
import Models.Position as Position exposing (Position)
import Models.Size as Size exposing (Size)
import String
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Attributes as SvgAttr
import Views.Diagram.Views as Views


horizontal :
    { settings : DiagramSettings.Settings
    , position : Position
    , selectedItem : SelectedItem
    , item : Item
    , onSelect : Maybe SelectedItemInfo -> msg
    , dragStart : Views.DragStart msg
    }
    -> Svg msg
horizontal { settings, position, selectedItem, item, onSelect, dragStart } =
    let
        color : Color
        color =
            getLineColor settings item

        ( offsetWidth, offsetHeight ) =
            Item.getOffsetSize item

        ( offsetX, offsetY ) =
            Item.getSettings item |> Maybe.withDefault ItemSettings.new |> ItemSettings.getOffset

        ( posX, posY ) =
            if ( offsetX, offsetY ) == Position.zero then
                position

            else
                position |> Tuple.mapBoth (\x -> x + offsetX) (\y -> y + offsetY)

        view_ : Svg msg
        view_ =
            Svg.g
                [ Events.onClickStopPropagation <|
                    onSelect <|
                        Just { item = item, position = Tuple.mapSecond (\y -> y - CardSize.toInt settings.size.width + offsetHeight + 72) position, displayAllMenu = False }
                ]
                [ Svg.line
                    [ SvgAttr.x1 <| String.fromInt posX
                    , SvgAttr.y1 <| String.fromInt posY
                    , SvgAttr.x2 <| String.fromInt <| posX + width
                    , SvgAttr.y2 <| String.fromInt posY
                    , SvgAttr.stroke <| Color.toString color
                    , SvgAttr.strokeWidth "6"
                    , SvgAttr.class "ts-line"
                    ]
                    []
                ]

        width : Int
        width =
            CardSize.toInt settings.size.width + offsetWidth
    in
    case selectedItem of
        Just item_ ->
            if Item.eq item_ item then
                let
                    selectedItemOffsetPosition : Position
                    selectedItemOffsetPosition =
                        Item.getOffset item_

                    selectedItemOffsetSize : Size
                    selectedItemOffsetSize =
                        Item.getOffsetSize item_

                    selectedItemPosition : Position
                    selectedItemPosition =
                        position
                            |> Tuple.mapBoth
                                (\x -> x + Position.getX selectedItemOffsetPosition)
                                (\y -> y + Position.getY selectedItemOffsetPosition)

                    selectedItemSize : Position
                    selectedItemSize =
                        ( CardSize.toInt settings.size.width, CardSize.toInt settings.size.height - 1 )
                            |> Tuple.mapBoth
                                (\w -> max 0 (w + Size.getWidth selectedItemOffsetSize))
                                (\h -> max 0 (h + Size.getHeight selectedItemOffsetSize))

                    ( x_, y_ ) =
                        ( Position.getX selectedItemPosition, Position.getY selectedItemPosition )
                in
                Svg.g
                    [ dragStart (Diagram.ItemMove <| Diagram.ItemTarget item) False ]
                    [ Svg.rect
                        [ SvgAttr.width <| String.fromInt <| Size.getWidth selectedItemSize + 16
                        , SvgAttr.height "16"
                        , SvgAttr.x (String.fromInt <| x_ - 8)
                        , SvgAttr.y (String.fromInt <| y_ - 8)
                        , SvgAttr.rx "1"
                        , SvgAttr.ry "1"
                        , SvgAttr.fill "transparent"
                        , SvgAttr.stroke <| Color.toString Color.background1Defalut
                        , SvgAttr.strokeWidth "1"
                        ]
                        []
                    , Svg.line
                        [ SvgAttr.x1 (String.fromInt <| x_ - 2)
                        , SvgAttr.y1 (String.fromInt <| y_)
                        , SvgAttr.x2 (String.fromInt <| x_ + Size.getWidth selectedItemSize + 4)
                        , SvgAttr.y2 (String.fromInt <| y_)
                        , SvgAttr.fill "transparent"
                        , SvgAttr.stroke <| Color.toString color
                        , SvgAttr.strokeWidth "6"
                        ]
                        []
                    , Views.resizeCircle { item = item, direction = Left, position = ( x_ - 8, y_ ), dragStart = dragStart }
                    , Views.resizeCircle { item = item, direction = Right, position = ( x_ + Size.getWidth selectedItemSize + 8, y_ ), dragStart = dragStart }
                    ]

            else
                view_

        Nothing ->
            view_


vertical :
    { settings : DiagramSettings.Settings
    , position : Position
    , selectedItem : SelectedItem
    , item : Item
    , onSelect : Maybe SelectedItemInfo -> msg
    , dragStart : Views.DragStart msg
    }
    -> Svg msg
vertical { settings, position, selectedItem, item, onSelect, dragStart } =
    let
        color : Color
        color =
            getLineColor settings item

        height : Int
        height =
            CardSize.toInt settings.size.height + offsetHeight

        ( _, offsetHeight ) =
            Item.getOffsetSize item

        ( posX, posY ) =
            Item.getPosition item position

        view_ : Svg msg
        view_ =
            Svg.g
                [ Events.onClickStopPropagation <|
                    onSelect <|
                        Just { item = item, position = position, displayAllMenu = False }
                ]
                [ Svg.line
                    [ SvgAttr.x1 <| String.fromInt posX
                    , SvgAttr.y1 <| String.fromInt posY
                    , SvgAttr.x2 <| String.fromInt <| posX
                    , SvgAttr.y2 <| String.fromInt <| posY + height
                    , SvgAttr.stroke <| Color.toString color
                    , SvgAttr.strokeWidth "6"
                    , SvgAttr.class "ts-line"
                    ]
                    []
                ]
    in
    case selectedItem of
        Just item_ ->
            if Item.eq item_ item then
                let
                    selectedItemOffsetPosition : Position
                    selectedItemOffsetPosition =
                        Item.getOffset item_

                    selectedItemOffsetSize : Size
                    selectedItemOffsetSize =
                        Item.getOffsetSize item_

                    selectedItemPosition : Position
                    selectedItemPosition =
                        position
                            |> Tuple.mapBoth
                                (\x -> x + Position.getX selectedItemOffsetPosition)
                                (\y -> y + Position.getY selectedItemOffsetPosition)

                    selectedItemSize : Size
                    selectedItemSize =
                        ( CardSize.toInt settings.size.width, CardSize.toInt settings.size.height - 1 )
                            |> Tuple.mapBoth
                                (\w -> max 0 (w + Size.getWidth selectedItemOffsetSize))
                                (\h -> max 0 (h + Size.getHeight selectedItemOffsetSize))

                    ( x_, y_ ) =
                        ( Position.getX selectedItemPosition, Position.getY selectedItemPosition )
                in
                Svg.g
                    [ dragStart (Diagram.ItemMove <| Diagram.ItemTarget item) False ]
                    [ Svg.rect
                        [ SvgAttr.width "16"
                        , SvgAttr.height <| String.fromInt <| Size.getHeight selectedItemSize + 16
                        , SvgAttr.x <| String.fromInt <| x_ - 8
                        , SvgAttr.y <| String.fromInt <| y_ - 8
                        , SvgAttr.rx "1"
                        , SvgAttr.ry "1"
                        , SvgAttr.fill "transparent"
                        , SvgAttr.stroke <| Color.toString Color.background1Defalut
                        , SvgAttr.strokeWidth "1"
                        ]
                        []
                    , Svg.line
                        [ SvgAttr.x1 (String.fromInt <| x_)
                        , SvgAttr.y1 (String.fromInt <| y_ - 2)
                        , SvgAttr.x2 (String.fromInt <| x_)
                        , SvgAttr.y2 (String.fromInt <| y_ + Size.getHeight selectedItemSize + 8)
                        , SvgAttr.fill "transparent"
                        , SvgAttr.stroke <| Color.toString color
                        , SvgAttr.strokeWidth "6"
                        ]
                        []
                    , Views.resizeCircle { item = item, direction = Top, position = ( x_, y_ - 8 ), dragStart = dragStart }
                    , Views.resizeCircle { item = item, direction = Bottom, position = ( x_, y_ + Size.getHeight selectedItemSize + 8 ), dragStart = dragStart }
                    ]

            else
                view_

        Nothing ->
            view_


getLineColor : DiagramSettings.Settings -> Item -> Color
getLineColor settings item =
    item
        |> Item.getBackgroundColor
        |> Maybe.withDefault settings.color.line
