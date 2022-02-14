module Views.Diagram.VerticalLine exposing (view)

import Events
import Models.Color as Color exposing (Color)
import Models.Diagram as Diagram exposing (Msg(..), ResizeDirection(..), SelectedItem)
import Models.DiagramSettings as DiagramSettings
import Models.Item as Item exposing (Item)
import Models.ItemSettings as ItemSettings
import Models.Position as Position exposing (Position)
import Models.Size as Size exposing (Size)
import String
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Attributes as SvgAttr
import Views.Diagram.Views as Views


view :
    { settings : DiagramSettings.Settings
    , position : Position
    , selectedItem : SelectedItem
    , item : Item
    }
    -> Svg Msg
view { settings, position, selectedItem, item } =
    let
        color : Color
        color =
            Views.getLineColor settings item

        ( offsetX, offsetY ) =
            Item.getItemSettings item |> Maybe.withDefault ItemSettings.new |> ItemSettings.getOffset

        ( _, offsetHeight ) =
            Item.getOffsetSize item

        ( posX, posY ) =
            if ( offsetX, offsetY ) == Position.zero then
                position

            else
                position |> Tuple.mapBoth (\x -> x + offsetX) (\y -> y + offsetY)

        height : Int
        height =
            settings.size.height + offsetHeight

        view_ : Svg Msg
        view_ =
            Svg.g
                [ Events.onClickStopPropagation <|
                    Select <|
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
            if Item.getLineNo item_ == Item.getLineNo item then
                let
                    selectedItemOffsetSize : Size
                    selectedItemOffsetSize =
                        Item.getOffsetSize item_

                    selectedItemOffsetPosition : Position
                    selectedItemOffsetPosition =
                        Item.getOffset item_

                    selectedItemPosition : Position
                    selectedItemPosition =
                        position
                            |> Tuple.mapBoth
                                (\x -> x + Position.getX selectedItemOffsetPosition)
                                (\y -> y + Position.getY selectedItemOffsetPosition)

                    selectedItemSize : Size
                    selectedItemSize =
                        ( settings.size.width, settings.size.height - 1 )
                            |> Tuple.mapBoth
                                (\w -> max 0 (w + Size.getWidth selectedItemOffsetSize))
                                (\h -> max 0 (h + Size.getHeight selectedItemOffsetSize))

                    ( x_, y_ ) =
                        ( Position.getX selectedItemPosition, Position.getY selectedItemPosition )
                in
                Svg.g
                    [ Diagram.dragStart (Diagram.ItemMove <| Diagram.ItemTarget item) False ]
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
                    , Views.resizeCircle item Top ( x_, y_ - 8 )
                    , Views.resizeCircle item Bottom ( x_, y_ + Size.getHeight selectedItemSize + 8 )
                    ]

            else
                view_

        Nothing ->
            view_
