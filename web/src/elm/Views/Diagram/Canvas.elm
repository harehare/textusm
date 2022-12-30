module Views.Diagram.Canvas exposing (view, viewBottom, viewImage)

import Constants
import Css exposing (property)
import Events
import Models.Color as Color exposing (Color)
import Models.Diagram as Diagram exposing (Msg(..), ResizeDirection(..), SelectedItem)
import Models.DiagramSettings as DiagramSettings
import Models.FontSize as FontSize
import Models.Item as Item exposing (Item, Items)
import Models.Position as Position exposing (Position)
import Models.Property as Property exposing (Property)
import Models.Size as Size exposing (Size)
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Attributes as SvgAttr
import Views.Diagram.Card as Card
import Views.Diagram.Views as Views


view : DiagramSettings.Settings -> Property -> Size -> Position -> SelectedItem -> Item -> Svg Msg
view settings property svgSize position selectedItem item =
    canvasBase settings property False svgSize position selectedItem item


viewBottom : DiagramSettings.Settings -> Property -> Size -> Position -> SelectedItem -> Item -> Svg Msg
viewBottom settings property svgSize position selectedItem item =
    canvasBase settings property True svgSize position selectedItem item


viewImage : DiagramSettings.Settings -> Property -> Size -> Position -> Item -> Svg Msg
viewImage settings property ( svgWidth, svgHeight ) ( posX, posY ) item =
    let
        colors : ( Color, Color )
        colors =
            getCanvasColor settings property item
    in
    Svg.g
        []
        [ canvasRect colors property ( posX, posY ) ( svgWidth, svgHeight )
        , case
            Item.getChildren item
                |> Item.unwrapChildren
                |> Item.head
          of
            Just item_ ->
                if Item.isImage item_ then
                    Views.image ( Constants.itemWidth - 5, svgHeight )
                        ( posX + 5, posY + 5 )
                        item_

                else
                    Svg.g [] []

            Nothing ->
                Svg.g [] []
        , title settings ( posX + 10, posY + 10 ) item
        ]


canvasBase : DiagramSettings.Settings -> Property -> Bool -> Size -> Position -> SelectedItem -> Item -> Svg Msg
canvasBase settings property isTitleBottom svgSize position selectedItem item =
    let
        colors : ( Color, Color )
        colors =
            getCanvasColor settings property item

        ( offsetWidth, offsetHeight ) =
            Item.getOffsetSize item

        ( posX, posY ) =
            Item.getPosition item position

        ( svgWidth, svgHeight ) =
            svgSize |> Tuple.mapBoth (\w -> w + offsetWidth) (\h -> h + offsetHeight)
    in
    case selectedItem of
        Just item_ ->
            if Item.getLineNo item_ == Item.getLineNo item then
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
                        svgSize
                            |> Tuple.mapBoth
                                (\w -> max 0 (w + Size.getWidth selectedItemOffsetSize))
                                (\h -> max 0 (h + Size.getHeight selectedItemOffsetSize))
                in
                Svg.g
                    [ Diagram.dragStart (Diagram.ItemMove <| Diagram.ItemTarget item) False ]
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
                        , color =
                            Item.getForegroundColor item
                                |> Maybe.map Color.toString
                                |> Maybe.withDefault settings.color.label
                                |> Color.fromString
                        , item = item_
                        }
                    , text
                        { settings = settings
                        , property = property
                        , svgWidth = Size.getWidth selectedItemSize
                        , position = selectedItemPosition
                        , selectedItem = selectedItem
                        , items = Item.unwrapChildren <| Item.getChildren item
                        }
                    , resizeCircle item TopLeft ( Position.getX selectedItemPosition, Position.getY selectedItemPosition )
                    , resizeCircle item TopRight ( Position.getX selectedItemPosition + Size.getWidth selectedItemSize, Position.getY selectedItemPosition )
                    , resizeCircle item BottomRight ( Position.getX selectedItemPosition + Size.getWidth selectedItemSize, Position.getY selectedItemPosition + Size.getHeight selectedItemSize )
                    , resizeCircle item BottomLeft ( Position.getX selectedItemPosition, Position.getY selectedItemPosition + Size.getHeight selectedItemSize )
                    ]

            else
                Svg.g []
                    [ canvasRect colors property ( posX, posY ) ( svgWidth, svgHeight )
                    , title settings
                        ( posX + 20
                        , posY
                            + (if isTitleBottom then
                                svgHeight - 20

                               else
                                20
                              )
                        )
                        item
                    , text
                        { settings = settings
                        , property = property
                        , svgWidth = svgWidth
                        , position = ( posX, posY )
                        , selectedItem = selectedItem
                        , items = Item.unwrapChildren <| Item.getChildren item
                        }
                    ]

        Nothing ->
            Svg.g
                [ Events.onClickStopPropagation <| Select <| Just { item = item, position = ( posX, posY + settings.size.height ), displayAllMenu = True } ]
                [ canvasRect colors property ( posX, posY ) ( svgWidth, svgHeight )
                , title settings
                    ( posX + 20
                    , posY
                        + (if isTitleBottom then
                            svgHeight - 20

                           else
                            20
                          )
                    )
                    item
                , text { settings = settings, property = property, svgWidth = svgWidth, position = ( posX, posY ), selectedItem = selectedItem, items = Item.unwrapChildren <| Item.getChildren item }
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


resizeCircle : Item -> ResizeDirection -> Position -> Svg Msg
resizeCircle item direction ( x, y ) =
    Views.resizeCircleBase 8 item direction ( x, y )


text : { settings : DiagramSettings.Settings, property : Property, svgWidth : Int, position : Position, selectedItem : SelectedItem, items : Items } -> Svg Msg
text { settings, property, svgWidth, position, selectedItem, items } =
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
                    }
            )
            items
        )


title : DiagramSettings.Settings -> Position -> Item -> Svg Msg
title settings ( posX, posY ) item =
    Svg.text_
        [ SvgAttr.x <| String.fromInt posX
        , SvgAttr.y <| String.fromInt <| posY + 14
        , SvgAttr.fontFamily <| DiagramSettings.fontStyle settings
        , SvgAttr.fill
            (Item.getForegroundColor item
                |> Maybe.map Color.toString
                |> Maybe.withDefault settings.color.label
            )
        , FontSize.svgStyledFontSize (Item.getFontSize item |> Maybe.withDefault FontSize.lg)
        , SvgAttr.fontWeight "bold"
        , SvgAttr.class "ts-title"
        , Events.onClickStopPropagation <| Select <| Just { item = item, position = ( posX, posY + settings.size.height ), displayAllMenu = True }
        ]
        [ Svg.text <| Item.getText item ]
