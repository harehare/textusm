module Diagram.View.TextNode exposing (root, view)

import Css
    exposing
        ( backgroundColor
        , borderStyle
        , center
        , color
        , focus
        , hex
        , marginLeft
        , marginTop
        , none
        , outline
        , padding4
        , px
        , textAlign
        , transparent
        , zero
        )
import Diagram.Types as Diagram exposing (ResizeDirection(..), SelectedItem, SelectedItemInfo)
import Diagram.Types.CardSize as CardSize
import Diagram.Types.Settings as DiagramSettings
import Diagram.View.Views as View
import Events
import Html.Styled as Html
import Html.Styled.Attributes as Attr exposing (css)
import Html.Styled.Events exposing (onBlur, onInput)
import String
import Style.Style as Style
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Attributes as SvgAttr
import Types.Color as Color exposing (Color)
import Types.FontSize as FontSize
import Types.Item as Item exposing (Item)
import Types.Position as Position exposing (Position)
import Types.Property as Property exposing (Property)
import Types.Size as Size exposing (Size)


view : { settings : DiagramSettings.Settings, property : Property, position : Position, selectedItem : SelectedItem, item : Item, onEditSelectedItem : String -> msg, onEndEditSelectedItem : Item -> msg, onSelect : Maybe SelectedItemInfo -> msg, dragStart : View.DragStart msg } -> Svg msg
view { settings, property, position, selectedItem, item, onEditSelectedItem, onEndEditSelectedItem, onSelect, dragStart } =
    let
        view_ : Svg msg
        view_ =
            let
                ( color, _ ) =
                    View.getItemColor settings property item

                ( posX, posY ) =
                    Item.getPosition item position

                ( offsetWidth, offsetHeight ) =
                    Item.getOffsetSize item

                ( width, height ) =
                    ( Property.getNodeWidth property, Property.getNodeHeight property )
                        |> Tuple.mapBoth
                            (\w -> Maybe.withDefault (CardSize.toInt settings.size.width) w)
                            (\h -> Maybe.withDefault (CardSize.toInt settings.size.height - 1) h)
                        |> Tuple.mapBoth
                            (\w -> w + offsetWidth)
                            (\h -> h + offsetHeight)
            in
            Svg.g
                [ Events.onClickStopPropagation <| onSelect <| Just { item = item, position = position, displayAllMenu = True } ]
                [ Svg.rect
                    [ SvgAttr.width <| String.fromInt width
                    , SvgAttr.height <| String.fromInt <| height - 1
                    , SvgAttr.x <| String.fromInt posX
                    , SvgAttr.y <| String.fromInt posY
                    , SvgAttr.fill <| Color.toString settings.backgroundColor
                    ]
                    []
                , textNode settings property ( posX, posY ) ( width, height ) color item
                ]
    in
    case selectedItem of
        Just item_ ->
            if Item.eq item_ item then
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
                        ( Property.getNodeWidth property, Property.getNodeHeight property )
                            |> Tuple.mapBoth
                                (\w -> Maybe.withDefault (CardSize.toInt settings.size.width) w)
                                (\h -> Maybe.withDefault (CardSize.toInt settings.size.height - 1) h)
                            |> Tuple.mapBoth
                                (\w -> max 0 (w + Size.getWidth selectedItemOffsetSize))
                                (\h -> max 0 (h + Size.getHeight selectedItemOffsetSize))

                    ( x_, y_ ) =
                        selectedItemPosition

                    ( width_, height_ ) =
                        selectedItemSize
                in
                Svg.g
                    [ dragStart (Diagram.ItemMove <| Diagram.ItemTarget item) False ]
                    [ Svg.rect
                        [ SvgAttr.width <| String.fromInt width_
                        , SvgAttr.height <| String.fromInt <| height_ - 1
                        , SvgAttr.x <| String.fromInt x_
                        , SvgAttr.y <| String.fromInt y_
                        , SvgAttr.strokeWidth "1"
                        , SvgAttr.stroke "transparent"
                        , SvgAttr.fill <| Color.toString settings.backgroundColor
                        , SvgAttr.class "ts-node"
                        ]
                        []
                    , View.resizeCircle { item = item, direction = TopLeft, position = ( x_ - 8, y_ - 8 ), dragStart = dragStart }
                    , View.resizeCircle { item = item, direction = TopRight, position = ( x_ + width_ + 8, y_ - 8 ), dragStart = dragStart }
                    , View.resizeCircle { item = item, direction = BottomRight, position = ( x_ + width_ + 8, y_ + height_ + 8 ), dragStart = dragStart }
                    , View.resizeCircle { item = item, direction = BottomLeft, position = ( x_ - 8, y_ + height_ + 8 ), dragStart = dragStart }
                    , textNodeInput { settings = settings, pos = ( x_, y_ ), size = ( width_, height_ ), item = item_, onEditSelectedItem = onEditSelectedItem, onEndEditSelectedItem = onEndEditSelectedItem, onSelect = onSelect }
                    ]

            else
                view_

        Nothing ->
            view_


textNode : DiagramSettings.Settings -> Property -> Position -> Size -> Color -> Item -> Svg msg
textNode settings property ( posX, posY ) ( svgWidth, svgHeight ) colour item =
    Svg.foreignObject
        [ SvgAttr.x <| String.fromInt posX
        , SvgAttr.y <| String.fromInt posY
        , SvgAttr.width <| String.fromInt svgWidth
        , SvgAttr.height <| String.fromInt svgHeight
        , SvgAttr.fill <| Color.toString colour
        , SvgAttr.color
            (Item.getForegroundColor item
                |> Maybe.withDefault Color.black
                |> Color.toString
            )
        , FontSize.svgStyledFontSize FontSize.default
        ]
        [ Html.div
            [ css
                [ Css.width <| px <| toFloat <| svgWidth
                , Css.height <| px <| toFloat <| svgHeight
                , DiagramSettings.fontFamiliy settings
                , Style.breakWord
                , Style.flexCenter
                , FontSize.cssFontSize <| Item.getFontSizeWithProperty item property
                ]
            , Attr.class "ts-node"
            ]
            [ Html.span
                [ css
                    [ backgroundColor <|
                        if Item.isHighlight item then
                            hex <| Color.toString Color.yellow

                        else
                            hex <| Color.toString Color.transparent
                    ]
                ]
                [ Html.text <| Item.getText item ]
            ]
        ]


textNodeInput : { settings : DiagramSettings.Settings, pos : Position, size : Size, item : Item, onEditSelectedItem : String -> msg, onEndEditSelectedItem : Item -> msg, onSelect : Maybe SelectedItemInfo -> msg } -> Svg msg
textNodeInput { settings, pos, size, item, onEditSelectedItem, onEndEditSelectedItem, onSelect } =
    Svg.foreignObject
        [ SvgAttr.x <| String.fromInt <| Position.getX pos
        , SvgAttr.y <| String.fromInt <| Position.getY pos
        , SvgAttr.width <| String.fromInt <| Size.getWidth size
        , SvgAttr.height <| String.fromInt <| Size.getHeight size
        ]
        [ Html.div
            [ css
                [ backgroundColor transparent
                , Css.width <| px <| toFloat <| Size.getWidth size
                , Css.height <| px <| toFloat <| Size.getHeight size
                , Style.flexCenter
                ]
            ]
            [ Html.input
                [ Attr.id "edit-item"
                , Attr.type_ "text"
                , Attr.autofocus True
                , Attr.autocomplete False
                , Attr.style "padding" "8px 8px 8px 0"
                , css
                    [ DiagramSettings.fontFamiliy settings
                    , padding4 (px 8) (px 8) (px 8) zero
                    , borderStyle none
                    , backgroundColor transparent
                    , outline none
                    , textAlign center
                    , FontSize.cssFontSize <| Maybe.withDefault FontSize.default <| Item.getFontSize item
                    , Css.width <| px <| toFloat <| Size.getWidth size - 20
                    , marginTop <| px 2
                    , marginLeft <| px 2
                    , color <|
                        hex
                            (Item.getForegroundColor item
                                |> Maybe.withDefault Color.black
                                |> Color.toString
                            )
                    , focus
                        [ outline none
                        ]
                    ]
                , Attr.value <| " " ++ String.trimLeft (Item.getText item)
                , onInput onEditSelectedItem
                , Events.onEnter <| onEndEditSelectedItem item
                , onBlur <| onSelect Nothing
                ]
                []
            ]
        ]


root :
    { settings : DiagramSettings.Settings
    , property : Property
    , position : Position
    , selectedItem : SelectedItem
    , item : Item
    , onEditSelectedItem : String -> msg
    , onEndEditSelectedItem : Item -> msg
    , onSelect : Maybe SelectedItemInfo -> msg
    }
    -> Svg msg
root { settings, property, position, selectedItem, item, onEditSelectedItem, onEndEditSelectedItem, onSelect } =
    let
        ( posX, posY ) =
            position

        borderColor : Color
        borderColor =
            Item.getBackgroundColor item
                |> Maybe.withDefault settings.color.activity.backgroundColor

        textColor : Color
        textColor =
            Item.getForegroundColor item
                |> Maybe.withDefault settings.color.activity.color

        ( width, height ) =
            ( Property.getNodeWidth property, Property.getNodeHeight property )
                |> Tuple.mapBoth
                    (\w -> Maybe.withDefault (CardSize.toInt settings.size.width) w)
                    (\h -> Maybe.withDefault (CardSize.toInt settings.size.height - 1) h)

        view_ : Svg msg
        view_ =
            Svg.g
                [ Events.onClickStopPropagation <| onSelect <| Just { item = item, position = ( posX, posY + CardSize.toInt settings.size.height ), displayAllMenu = True } ]
                [ Svg.rect
                    [ SvgAttr.width <| String.fromInt width
                    , SvgAttr.height <| String.fromInt <| height
                    , SvgAttr.x <| String.fromInt posX
                    , SvgAttr.y <| String.fromInt posY
                    , SvgAttr.strokeWidth "3"
                    , SvgAttr.stroke <| Color.toString borderColor
                    , SvgAttr.rx "32"
                    , SvgAttr.ry "32"
                    , SvgAttr.fill <| Color.toString settings.backgroundColor
                    , SvgAttr.class "ts-node"
                    ]
                    []
                , textNode settings property ( posX, posY ) ( CardSize.toInt settings.size.width, CardSize.toInt settings.size.height ) textColor item
                ]
    in
    case selectedItem of
        Just item_ ->
            if Item.eq item_ item then
                Svg.g []
                    [ Svg.rect
                        [ SvgAttr.width <| String.fromInt <| CardSize.toInt settings.size.width
                        , SvgAttr.height <| String.fromInt <| CardSize.toInt settings.size.height - 1
                        , SvgAttr.x <| String.fromInt posX
                        , SvgAttr.y <| String.fromInt posY
                        , SvgAttr.strokeWidth "3"
                        , SvgAttr.stroke <| Color.toString borderColor
                        , SvgAttr.rx "32"
                        , SvgAttr.ry "32"
                        , SvgAttr.fill <| Color.toString settings.backgroundColor
                        , SvgAttr.class "ts-node"
                        ]
                        []
                    , textNodeInput
                        { settings = settings
                        , pos = ( posX, posY )
                        , size = ( CardSize.toInt settings.size.width, CardSize.toInt settings.size.height )
                        , item = item_
                        , onEditSelectedItem = onEditSelectedItem
                        , onEndEditSelectedItem = onEndEditSelectedItem
                        , onSelect = onSelect
                        }
                    ]

            else
                view_

        Nothing ->
            view_
