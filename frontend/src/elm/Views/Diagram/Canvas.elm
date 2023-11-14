module Views.Diagram.Canvas exposing (view, viewBottom, viewImage)

import Constants
import Events
import Models.Color as Color exposing (Color)
import Models.Diagram as Diagram exposing (ResizeDirection(..), SelectedItem, SelectedItemInfo)
import Models.Diagram.Settings as DiagramSettings
import Models.FontSize as FontSize
import Models.Item as Item exposing (Item, Items)
import Models.Position as Position exposing (Position)
import Models.Property as Property exposing (Property)
import Models.Size as Size exposing (Size)
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Attributes as SvgAttr
import Views.Diagram.Card as Card
import Views.Diagram.Views as Views


view :
    { settings : DiagramSettings.Settings
    , property : Property
    , size : Size
    , position : Position
    , selectedItem : SelectedItem
    , item : Item
    , onEditSelectedItem : String -> msg
    , onEndEditSelectedItem : Item -> msg
    , onSelect : Maybe SelectedItemInfo -> msg
    , dragStart : Views.DragStart msg
    }
    -> Svg msg
view { settings, property, size, position, selectedItem, item, onEditSelectedItem, onEndEditSelectedItem, onSelect, dragStart } =
    canvasBase
        { settings = settings
        , property = property
        , isTitleBottom = False
        , size = size
        , position = position
        , selectedItem = selectedItem
        , item = item
        , onEditSelectedItem = onEditSelectedItem
        , onEndEditSelectedItem = onEndEditSelectedItem
        , onSelect = onSelect
        , dragStart = dragStart
        }


viewBottom :
    { settings : DiagramSettings.Settings
    , property : Property
    , size : Size
    , position : Position
    , selectedItem : SelectedItem
    , item : Item
    , onEditSelectedItem : String -> msg
    , onEndEditSelectedItem : Item -> msg
    , onSelect : Maybe SelectedItemInfo -> msg
    , dragStart : Views.DragStart msg
    }
    -> Svg msg
viewBottom { settings, property, size, position, selectedItem, item, onEditSelectedItem, onEndEditSelectedItem, onSelect, dragStart } =
    canvasBase
        { settings = settings
        , property = property
        , isTitleBottom = True
        , size = size
        , position = position
        , selectedItem = selectedItem
        , item = item
        , onEditSelectedItem = onEditSelectedItem
        , onEndEditSelectedItem = onEndEditSelectedItem
        , onSelect = onSelect
        , dragStart = dragStart
        }


viewImage :
    { settings : DiagramSettings.Settings
    , property : Property
    , size : Size
    , position : Position
    , item : Item
    , onSelect : Maybe SelectedItemInfo -> msg
    }
    -> Svg msg
viewImage { settings, property, size, position, item, onSelect } =
    let
        colors : ( Color, Color )
        colors =
            getCanvasColor settings property item
    in
    Svg.g
        []
        [ canvasRect colors property position size
        , case
            Item.getChildren item
                |> Item.unwrapChildren
                |> Item.head
          of
            Just item_ ->
                if Item.isImage item_ then
                    Views.image
                        { size = Tuple.mapFirst (\_ -> Constants.itemWidth - 5) position
                        , position = Tuple.mapBoth (\x -> x + 5) (\y -> y + 5) position
                        , item = item_
                        }

                else
                    Svg.g [] []

            Nothing ->
                Svg.g [] []
        , title
            { settings = settings
            , position = Tuple.mapBoth (\x -> x + 10) (\y -> y + 10) position
            , item = item
            , onSelect = onSelect
            }
        ]


canvasBase :
    { settings : DiagramSettings.Settings
    , property : Property
    , isTitleBottom : Bool
    , size : Size
    , position : Position
    , selectedItem : SelectedItem
    , item : Item
    , onEditSelectedItem : String -> msg
    , onEndEditSelectedItem : Item -> msg
    , onSelect : Maybe SelectedItemInfo -> msg
    , dragStart : Views.DragStart msg
    }
    -> Svg msg
canvasBase { settings, property, isTitleBottom, size, position, selectedItem, item, onEditSelectedItem, onEndEditSelectedItem, onSelect, dragStart } =
    let
        colors : ( Color, Color )
        colors =
            getCanvasColor settings property item

        ( offsetWidth, offsetHeight ) =
            Item.getOffsetSize item

        ( posX, posY ) =
            Item.getPosition item position

        ( svgWidth, svgHeight ) =
            size |> Tuple.mapBoth (\w -> w + offsetWidth) (\h -> h + offsetHeight)
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
                        size
                            |> Tuple.mapBoth
                                (\w -> max 0 (w + Size.getWidth selectedItemOffsetSize))
                                (\h -> max 0 (h + Size.getHeight selectedItemOffsetSize))
                in
                Svg.g
                    [ dragStart (Diagram.ItemMove <| Diagram.ItemTarget item) False ]
                    [ canvasRect colors property selectedItemPosition selectedItemSize
                    , Views.inputBoldView
                        { settings = settings
                        , fontSize =
                            Item.getFontSize item
                                |> Maybe.withDefault FontSize.lg
                        , position =
                            selectedItemPosition
                                |> Tuple.mapBoth
                                    (\x -> x + 14)
                                    (\y ->
                                        y
                                            + (if isTitleBottom then
                                                svgHeight - 38

                                               else
                                                6
                                              )
                                    )
                        , size = ( Size.getWidth selectedItemSize, settings.size.height )
                        , color = Item.getForegroundColor item |> Maybe.withDefault settings.color.label
                        , item = item_
                        , onEditSelectedItem = onEditSelectedItem
                        , onEndEditSelectedItem = onEndEditSelectedItem
                        , onSelect = onSelect
                        }
                    , text
                        { settings = settings
                        , property = property
                        , svgWidth = Size.getWidth selectedItemSize
                        , position = selectedItemPosition
                        , selectedItem = selectedItem
                        , items = Item.unwrapChildren <| Item.getChildren item
                        , onEditSelectedItem = onEditSelectedItem
                        , onEndEditSelectedItem = onEndEditSelectedItem
                        , onSelect = onSelect
                        , dragStart = dragStart
                        }
                    , resizeCircle
                        { item = item
                        , direction = TopLeft
                        , position = ( Position.getX selectedItemPosition, Position.getY selectedItemPosition )
                        , dragStart = dragStart
                        }
                    , resizeCircle
                        { item = item
                        , direction = TopRight
                        , position = ( Position.getX selectedItemPosition + Size.getWidth selectedItemSize, Position.getY selectedItemPosition )
                        , dragStart = dragStart
                        }
                    , resizeCircle
                        { item = item
                        , direction = BottomRight
                        , position = ( Position.getX selectedItemPosition + Size.getWidth selectedItemSize, Position.getY selectedItemPosition + Size.getHeight selectedItemSize )
                        , dragStart = dragStart
                        }
                    , resizeCircle
                        { item = item
                        , direction = BottomLeft
                        , position = ( Position.getX selectedItemPosition, Position.getY selectedItemPosition + Size.getHeight selectedItemSize )
                        , dragStart = dragStart
                        }
                    ]

            else
                Svg.g []
                    [ canvasRect colors property ( posX, posY ) ( svgWidth, svgHeight )
                    , title
                        { settings = settings
                        , position =
                            ( posX + 20
                            , posY
                                + (if isTitleBottom then
                                    svgHeight - 20

                                   else
                                    20
                                  )
                            )
                        , item = item
                        , onSelect = onSelect
                        }
                    , text
                        { settings = settings
                        , property = property
                        , svgWidth = svgWidth
                        , position = ( posX, posY )
                        , selectedItem = selectedItem
                        , items = Item.unwrapChildren <| Item.getChildren item
                        , onEditSelectedItem = onEditSelectedItem
                        , onEndEditSelectedItem = onEndEditSelectedItem
                        , onSelect = onSelect
                        , dragStart = dragStart
                        }
                    ]

        Nothing ->
            Svg.g
                [ Events.onClickStopPropagation <| onSelect <| Just { item = item, position = ( posX, posY + settings.size.height ), displayAllMenu = True } ]
                [ canvasRect colors property ( posX, posY ) ( svgWidth, svgHeight )
                , title
                    { settings = settings
                    , position =
                        ( posX + 20
                        , posY
                            + (if isTitleBottom then
                                svgHeight - 20

                               else
                                20
                              )
                        )
                    , item = item
                    , onSelect = onSelect
                    }
                , text
                    { settings = settings
                    , property = property
                    , svgWidth = svgWidth
                    , position = ( posX, posY )
                    , selectedItem = selectedItem
                    , items = Item.unwrapChildren <| Item.getChildren item
                    , onEditSelectedItem = onEditSelectedItem
                    , onEndEditSelectedItem = onEndEditSelectedItem
                    , onSelect = onSelect
                    , dragStart = dragStart
                    }
                ]


canvasRect : ( Color, Color ) -> Property -> Position -> Size -> Svg msg
canvasRect ( foregroundColor, backgroundColor ) property ( posX, posY ) ( rectWidth, rectHeight ) =
    Svg.rect
        [ SvgAttr.width <| String.fromInt rectWidth
        , SvgAttr.height <| String.fromInt rectHeight
        , SvgAttr.stroke (Property.getLineColor property |> Maybe.map Color.toString |> Maybe.withDefault (foregroundColor |> Color.toString))
        , SvgAttr.fill <| Color.toString backgroundColor
        , SvgAttr.strokeWidth (Property.getLineSize property |> Maybe.map String.fromInt |> Maybe.withDefault "10")
        , SvgAttr.x <| String.fromInt posX
        , SvgAttr.y <| String.fromInt posY
        , SvgAttr.class "ts-canvas"
        ]
        []


getCanvasColor : DiagramSettings.Settings -> Property -> Item -> ( Color, Color )
getCanvasColor settings property item =
    case ( Item.getForegroundColor item, Item.getBackgroundColor item ) of
        ( Just f, Just b ) ->
            ( f, b )

        ( Just f, Nothing ) ->
            ( f
            , Property.getCanvasBackgroundColor property
                |> Maybe.withDefault Color.transparent
            )

        ( Nothing, Just b ) ->
            ( DiagramSettings.getLineColor settings property
            , b
            )

        _ ->
            ( DiagramSettings.getLineColor settings property
            , Property.getCanvasBackgroundColor property
                |> Maybe.withDefault Color.transparent
            )


resizeCircle : { item : Item, direction : ResizeDirection, position : Position, dragStart : Views.DragStart msg } -> Svg msg
resizeCircle { item, direction, position, dragStart } =
    Views.resizeCircleBase { size = 8, item = item, direction = direction, position = position, dragStart = dragStart }


text :
    { settings : DiagramSettings.Settings
    , property : Property
    , svgWidth : Int
    , position : Position
    , selectedItem : SelectedItem
    , items : Items
    , onEditSelectedItem : String -> msg
    , onEndEditSelectedItem : Item -> msg
    , onSelect : Maybe SelectedItemInfo -> msg
    , dragStart : Views.DragStart msg
    }
    -> Svg msg
text { settings, property, svgWidth, position, selectedItem, items, onEditSelectedItem, onEndEditSelectedItem, onSelect, dragStart } =
    let
        newSettings : DiagramSettings.Settings
        newSettings =
            settings |> DiagramSettings.ofWidth.set (svgWidth - Constants.itemMargin * 2)

        ( posX, posY ) =
            position
    in
    Svg.g []
        (Item.indexedMap
            (\i item ->
                Card.viewWithDefaultColor
                    { settings = newSettings
                    , property = property
                    , position = ( posX + 16, posY + i * (settings.size.height + Constants.itemMargin) + Constants.itemMargin + 35 )
                    , selectedItem = selectedItem
                    , item = item
                    , canMove = False
                    , onEditSelectedItem = onEditSelectedItem
                    , onEndEditSelectedItem = onEndEditSelectedItem
                    , onSelect = onSelect
                    , dragStart = dragStart
                    }
            )
            items
        )


title : { settings : DiagramSettings.Settings, position : Position, item : Item, onSelect : Maybe SelectedItemInfo -> msg } -> Svg msg
title { settings, position, item, onSelect } =
    Svg.text_
        [ SvgAttr.x <| String.fromInt <| Position.getX position
        , SvgAttr.y <| String.fromInt <| Position.getY position + 14
        , SvgAttr.fontFamily <| DiagramSettings.fontStyle settings
        , SvgAttr.fill <|
            Color.toString
                (Item.getForegroundColor item
                    |> Maybe.withDefault settings.color.label
                )
        , FontSize.svgStyledFontSize (Item.getFontSize item |> Maybe.withDefault FontSize.lg)
        , SvgAttr.fontWeight "bold"
        , SvgAttr.class "ts-title"
        , Events.onClickStopPropagation <|
            onSelect <|
                Just
                    { item = item
                    , position = Tuple.mapSecond (\y -> y + settings.size.height) position
                    , displayAllMenu = True
                    }
        ]
        [ Svg.text <| Item.getText item ]
