module Views.Diagram.Views exposing
    ( canvas
    , canvasBottom
    , canvasImage
    , card
    , grid
    , horizontalLine
    , node
    , rootTextNode
    , text
    , verticalLine
    )

import Constants
import Events
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events exposing (onInput)
import Markdown
import Models.Diagram as Diagram exposing (MoveState(..), Msg(..), ResizeDirection(..), SelectedItem, Settings, settingsOfWidth)
import String
import Svg exposing (Svg)
import Svg.Attributes as SvgAttr
import Types.Color as Color
import Types.FontSize as FontSize exposing (FontSize)
import Types.Item as Item exposing (Item, ItemType(..), Items)
import Types.ItemSettings as ItemSettings
import Types.Position as Position exposing (Position)
import Types.Size as Size exposing (Size)


type alias RgbColor =
    String


getItemColor : Settings -> Item -> ( RgbColor, RgbColor )
getItemColor settings item =
    case
        ( Item.getItemType item
        , Item.getItemSettings item |> Maybe.withDefault ItemSettings.new |> ItemSettings.getForegroundColor
        , Item.getItemSettings item |> Maybe.withDefault ItemSettings.new |> ItemSettings.getBackgroundColor
        )
    of
        ( _, Just c, Just b ) ->
            ( Color.toString c, Color.toString b )

        ( Activities, Just c, Nothing ) ->
            ( Color.toString c, settings.color.activity.backgroundColor )

        ( Activities, Nothing, Just b ) ->
            ( settings.color.activity.color, Color.toString b )

        ( Activities, Nothing, Nothing ) ->
            ( settings.color.activity.color, settings.color.activity.backgroundColor )

        ( Tasks, Just c, Nothing ) ->
            ( Color.toString c, settings.color.task.backgroundColor )

        ( Tasks, Nothing, Just b ) ->
            ( settings.color.task.color, Color.toString b )

        ( Tasks, Nothing, Nothing ) ->
            ( settings.color.task.color, settings.color.task.backgroundColor )

        ( _, Just c, Nothing ) ->
            ( Color.toString c, settings.color.story.backgroundColor )

        ( _, Nothing, Just b ) ->
            ( settings.color.story.color, Color.toString b )

        _ ->
            ( settings.color.story.color, settings.color.story.backgroundColor )


card : { settings : Settings, position : Position, selectedItem : SelectedItem, item : Item, canMove : Bool } -> Svg Msg
card { settings, position, selectedItem, item, canMove } =
    let
        ( color, backgroundColor ) =
            getItemColor settings item

        ( offsetX, offsetY ) =
            Item.getItemSettings item |> Maybe.withDefault ItemSettings.new |> ItemSettings.getOffset

        ( offsetWidth, offsetHeight ) =
            Item.getOffsetSize item

        ( posX, posY ) =
            if ( offsetX, offsetY ) == Position.zero then
                position

            else
                position |> Tuple.mapBoth (\x -> x + offsetX) (\y -> y + offsetY)

        ( width, height ) =
            ( settings.size.width, settings.size.height - 1 ) |> Tuple.mapBoth (\w -> w + offsetWidth) (\h -> h + offsetHeight)

        view_ =
            Svg.g
                [ Events.onClickStopPropagation <|
                    Select <|
                        Just ( item, position )
                ]
                [ Svg.rect
                    [ SvgAttr.width <| String.fromInt width
                    , SvgAttr.height <| String.fromInt height
                    , SvgAttr.x <| String.fromInt posX
                    , SvgAttr.y <| String.fromInt posY
                    , SvgAttr.fill backgroundColor
                    , SvgAttr.rx "1"
                    , SvgAttr.ry "1"
                    , SvgAttr.style "filter:url(#shadow)"
                    , SvgAttr.class "ts-card"
                    ]
                    []
                , text settings
                    ( posX, posY )
                    ( width, height )
                    color
                    (Item.getFontSize item)
                    (Item.getText item)
                ]
    in
    case selectedItem of
        Just item_ ->
            if Item.getLineNo item_ == Item.getLineNo item then
                let
                    selectedItemOffsetSize =
                        Item.getOffsetSize item_

                    selectedItemOffsetPosition =
                        Item.getOffset item_

                    selectedItemPosition =
                        position
                            |> Tuple.mapBoth
                                (\x -> x + Position.getX selectedItemOffsetPosition)
                                (\y -> y + Position.getY selectedItemOffsetPosition)

                    selectedItemSize =
                        ( settings.size.width, settings.size.height - 1 )
                            |> Tuple.mapBoth
                                (\w -> max 0 (w + Size.getWidth selectedItemOffsetSize))
                                (\h -> max 0 (h + Size.getHeight selectedItemOffsetSize))

                    ( x_, y_ ) =
                        ( Position.getX selectedItemPosition, Position.getY selectedItemPosition )
                in
                Svg.g
                    [ if canMove then
                        Diagram.dragStart (Diagram.ItemMove <| Diagram.ItemTarget item) False

                      else
                        SvgAttr.style ""
                    ]
                    [ Svg.rect
                        [ SvgAttr.width <| String.fromInt <| Size.getWidth selectedItemSize + 16
                        , SvgAttr.height <| String.fromInt <| Size.getHeight selectedItemSize + 16
                        , SvgAttr.x (String.fromInt <| x_ - 8)
                        , SvgAttr.y (String.fromInt <| y_ - 8)
                        , SvgAttr.rx "1"
                        , SvgAttr.ry "1"
                        , SvgAttr.fill "transparent"
                        , SvgAttr.stroke "#266b9a"
                        , SvgAttr.strokeWidth "1"
                        ]
                        []
                    , Svg.rect
                        [ SvgAttr.width <| String.fromInt <| Size.getWidth selectedItemSize + 4
                        , SvgAttr.height <| String.fromInt <| Size.getHeight selectedItemSize + 4
                        , SvgAttr.x (String.fromInt <| x_ - 2)
                        , SvgAttr.y (String.fromInt <| y_ - 2)
                        , SvgAttr.rx "1"
                        , SvgAttr.ry "1"
                        , SvgAttr.fill backgroundColor
                        , SvgAttr.style "filter:url(#shadow)"
                        ]
                        []
                    , resizeRect item TopLeft ( x_ - 8, y_ - 8 )
                    , resizeRect item TopRight ( x_ + Size.getWidth selectedItemSize + 8, y_ - 8 )
                    , resizeRect item BottomRight ( x_ + Size.getWidth selectedItemSize + 8, y_ + Size.getHeight selectedItemSize + 8 )
                    , resizeRect item BottomLeft ( x_ - 8, y_ + Size.getHeight selectedItemSize + 8 )
                    , inputView
                        { settings = settings
                        , fontSize = Item.getFontSize item
                        , position = ( x_, y_ )
                        , size = selectedItemSize
                        , color = color
                        , item = item_
                        }
                    ]

            else
                view_

        Nothing ->
            view_


horizontalLine : { settings : Settings, position : Position, selectedItem : SelectedItem, item : Item } -> Svg Msg
horizontalLine { settings, position, selectedItem, item } =
    let
        ( _, color ) =
            getItemColor settings item

        ( offsetX, offsetY ) =
            Item.getItemSettings item |> Maybe.withDefault ItemSettings.new |> ItemSettings.getOffset

        ( offsetWidth, _ ) =
            Item.getOffsetSize item

        ( posX, posY ) =
            if ( offsetX, offsetY ) == Position.zero then
                position

            else
                position |> Tuple.mapBoth (\x -> x + offsetX) (\y -> y + offsetY)

        width =
            settings.size.width + offsetWidth

        view_ =
            Svg.g
                [ Events.onClickStopPropagation <|
                    Select <|
                        Just ( item, position )
                ]
                [ Svg.line
                    [ SvgAttr.x1 <| String.fromInt posX
                    , SvgAttr.y1 <| String.fromInt posY
                    , SvgAttr.x2 <| String.fromInt <| posX + width
                    , SvgAttr.y2 <| String.fromInt posY
                    , SvgAttr.stroke color
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
                    selectedItemOffsetSize =
                        Item.getOffsetSize item_

                    selectedItemOffsetPosition =
                        Item.getOffset item_

                    selectedItemPosition =
                        position
                            |> Tuple.mapBoth
                                (\x -> x + Position.getX selectedItemOffsetPosition)
                                (\y -> y + Position.getY selectedItemOffsetPosition)

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
                        [ SvgAttr.width <| String.fromInt <| Size.getWidth selectedItemSize + 16
                        , SvgAttr.height "16"
                        , SvgAttr.x (String.fromInt <| x_ - 8)
                        , SvgAttr.y (String.fromInt <| y_ - 8)
                        , SvgAttr.rx "1"
                        , SvgAttr.ry "1"
                        , SvgAttr.fill "transparent"
                        , SvgAttr.stroke "#266b9a"
                        , SvgAttr.strokeWidth "1"
                        ]
                        []
                    , Svg.line
                        [ SvgAttr.x1 (String.fromInt <| x_ - 2)
                        , SvgAttr.y1 (String.fromInt <| y_)
                        , SvgAttr.x2 (String.fromInt <| x_ + Size.getWidth selectedItemSize + 4)
                        , SvgAttr.y2 (String.fromInt <| y_)
                        , SvgAttr.fill "transparent"
                        , SvgAttr.stroke color
                        , SvgAttr.strokeWidth "6"
                        ]
                        []
                    , resizeRect item Left ( x_ - 8, y_ )
                    , resizeRect item Right ( x_ + Size.getWidth selectedItemSize + 8, y_ )
                    ]

            else
                view_

        Nothing ->
            view_


verticalLine : { settings : Settings, position : Position, selectedItem : SelectedItem, item : Item } -> Svg Msg
verticalLine { settings, position, selectedItem, item } =
    let
        ( _, color ) =
            getItemColor settings item

        ( offsetX, offsetY ) =
            Item.getItemSettings item |> Maybe.withDefault ItemSettings.new |> ItemSettings.getOffset

        ( _, offsetHeight ) =
            Item.getOffsetSize item

        ( posX, posY ) =
            if ( offsetX, offsetY ) == Position.zero then
                position

            else
                position |> Tuple.mapBoth (\x -> x + offsetX) (\y -> y + offsetY)

        height =
            settings.size.height + offsetHeight

        view_ =
            Svg.g
                [ Events.onClickStopPropagation <|
                    Select <|
                        Just ( item, position )
                ]
                [ Svg.line
                    [ SvgAttr.x1 <| String.fromInt posX
                    , SvgAttr.y1 <| String.fromInt posY
                    , SvgAttr.x2 <| String.fromInt <| posX
                    , SvgAttr.y2 <| String.fromInt <| posY + height
                    , SvgAttr.stroke color
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
                    selectedItemOffsetSize =
                        Item.getOffsetSize item_

                    selectedItemOffsetPosition =
                        Item.getOffset item_

                    selectedItemPosition =
                        position
                            |> Tuple.mapBoth
                                (\x -> x + Position.getX selectedItemOffsetPosition)
                                (\y -> y + Position.getY selectedItemOffsetPosition)

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
                        , SvgAttr.stroke "#266b9a"
                        , SvgAttr.strokeWidth "1"
                        ]
                        []
                    , Svg.line
                        [ SvgAttr.x1 (String.fromInt <| x_)
                        , SvgAttr.y1 (String.fromInt <| y_ - 2)
                        , SvgAttr.x2 (String.fromInt <| x_)
                        , SvgAttr.y2 (String.fromInt <| y_ + Size.getHeight selectedItemSize + 8)
                        , SvgAttr.fill "transparent"
                        , SvgAttr.stroke color
                        , SvgAttr.strokeWidth "6"
                        ]
                        []
                    , resizeRect item Top ( x_, y_ - 8 )
                    , resizeRect item Bottom ( x_, y_ + Size.getHeight selectedItemSize + 8 )
                    ]

            else
                view_

        Nothing ->
            view_


resizeRect : Item -> ResizeDirection -> Position -> Svg Msg
resizeRect item direction ( x, y ) =
    Svg.circle
        [ SvgAttr.cx <| String.fromInt x
        , SvgAttr.cy <| String.fromInt y
        , SvgAttr.r "5"
        , SvgAttr.style <|
            case direction of
                TopLeft ->
                    "cursor: nwse-resize"

                TopRight ->
                    "cursor: nesw-resize"

                BottomLeft ->
                    "cursor: nesw-resize"

                BottomRight ->
                    "cursor: nwse-resize"

                Left ->
                    "cursor: w-resize"

                Right ->
                    "cursor: e-resize"

                Top ->
                    "cursor: n-resize"

                Bottom ->
                    "cursor: s-resize"
        , SvgAttr.fill "#FEFEFE"
        , SvgAttr.strokeWidth "2"
        , SvgAttr.stroke "#BDBDBD"
        , Diagram.dragStart (ItemResize item direction) False
        ]
        []


inputView :
    { settings : Settings
    , fontSize : FontSize
    , position : Position
    , size : Size
    , color : RgbColor
    , item : Item
    }
    -> Svg Msg
inputView { settings, fontSize, position, size, color, item } =
    Svg.foreignObject
        [ SvgAttr.x <| String.fromInt <| Position.getX position
        , SvgAttr.y <| String.fromInt <| Position.getY position
        , SvgAttr.width <| String.fromInt <| Size.getWidth size
        , SvgAttr.height <| String.fromInt <| Size.getHeight size
        ]
        [ Html.input
            [ Attr.id "edit-item"
            , Attr.type_ "text"
            , Attr.autofocus True
            , Attr.autocomplete False
            , Attr.style "padding" "8px 8px 8px 0"
            , Attr.style "font-family" <| Diagram.fontStyle settings
            , Attr.style "color" color
            , Attr.style "background-color" "transparent"
            , Attr.style "border" "none"
            , Attr.style "outline" "none"
            , Attr.style "width" (String.fromInt (Size.getWidth size - 20) ++ "px")
            , Attr.style "font-size" <| String.fromInt (FontSize.unwrap fontSize) ++ "px"
            , Attr.style "margin-left" "2px"
            , Attr.style "margin-top" "2px"
            , Attr.value <| " " ++ String.trimLeft (Item.getText item)
            , onInput EditSelectedItem
            , Events.onEnter <| EndEditSelectedItem item
            ]
            []
        ]


text : Settings -> Position -> Size -> RgbColor -> FontSize -> String -> Svg Msg
text settings ( posX, posY ) ( svgWidth, svgHeight ) colour fs cardText =
    if Item.isMarkdown cardText then
        Svg.foreignObject
            [ SvgAttr.x <| String.fromInt posX
            , SvgAttr.y <| String.fromInt posY
            , SvgAttr.width <| String.fromInt svgWidth
            , SvgAttr.height <| String.fromInt svgHeight
            , SvgAttr.fill colour
            , SvgAttr.color colour
            , FontSize.svgFontSize fs
            , SvgAttr.class "select-none ts-text"
            ]
            [ markdown settings
                colour
                (String.trim cardText
                    |> String.dropLeft 3
                    |> String.trim
                )
            ]

    else if Item.isImage cardText then
        image ( svgWidth, svgHeight ) ( posX, posY ) <| String.trim cardText

    else if String.length cardText > 20 then
        Svg.foreignObject
            [ SvgAttr.x <| String.fromInt posX
            , SvgAttr.y <| String.fromInt posY
            , SvgAttr.width <| String.fromInt svgWidth
            , SvgAttr.height <| String.fromInt svgHeight
            , SvgAttr.fill colour
            , SvgAttr.color colour
            , FontSize.svgFontSize fs
            , SvgAttr.class "select-none ts-text"
            ]
            [ Html.div
                [ Attr.style "padding" "8px"
                , Attr.style "font-family" <| Diagram.fontStyle settings
                , Attr.style "word-wrap" "break-word"
                ]
                [ Html.text cardText ]
            ]

    else
        Svg.text_
            [ SvgAttr.x <| String.fromInt <| posX + 6
            , SvgAttr.y <| String.fromInt <| posY + 24
            , SvgAttr.width <| String.fromInt svgWidth
            , SvgAttr.height <| String.fromInt svgHeight
            , SvgAttr.fill colour
            , SvgAttr.color colour
            , SvgAttr.fontFamily <| Diagram.fontStyle settings
            , FontSize.svgFontSize fs
            , SvgAttr.class "select-none"
            ]
            [ Svg.text cardText ]


markdown : Settings -> RgbColor -> String -> Html Msg
markdown settings colour t =
    Markdown.toHtml
        [ Attr.class "md-content"
        , Attr.style "font-family" ("'" ++ settings.font ++ "', sans-serif")
        , Attr.style "color" colour
        ]
        t


canvas : Settings -> Size -> Position -> SelectedItem -> Item -> Svg Msg
canvas settings ( svgWidth, svgHeight ) ( posX, posY ) selectedItem item =
    Svg.g
        []
        (case selectedItem of
            Just item_ ->
                if Item.getLineNo item_ == Item.getLineNo item then
                    [ canvasRect settings ( posX, posY ) ( svgWidth, svgHeight )
                    , inputView
                        { settings = settings
                        , fontSize =
                            Maybe.andThen (\f -> Just <| ItemSettings.getFontSize f) (Item.getItemSettings item)
                                |> Maybe.withDefault FontSize.lg
                        , position = ( posX, posY )
                        , size = ( svgWidth, settings.size.height )
                        , color =
                            Item.getItemSettings item
                                |> Maybe.withDefault ItemSettings.new
                                |> ItemSettings.getForegroundColor
                                |> Maybe.andThen (\c -> Just <| Color.toString c)
                                |> Maybe.withDefault settings.color.label
                        , item = item_
                        }
                    , canvasText { settings = settings, svgWidth = svgWidth, position = ( posX, posY ), selectedItem = selectedItem, items = Item.unwrapChildren <| Item.getChildren item }
                    ]

                else
                    [ canvasRect settings ( posX, posY ) ( svgWidth, svgHeight )
                    , title settings ( posX + 20, posY + 20 ) item
                    , canvasText { settings = settings, svgWidth = svgWidth, position = ( posX, posY ), selectedItem = selectedItem, items = Item.unwrapChildren <| Item.getChildren item }
                    ]

            Nothing ->
                [ canvasRect settings ( posX, posY ) ( svgWidth, svgHeight )
                , title settings ( posX + 20, posY + 20 ) item
                , canvasText { settings = settings, svgWidth = svgWidth, position = ( posX, posY ), selectedItem = selectedItem, items = Item.unwrapChildren <| Item.getChildren item }
                ]
        )


canvasBottom : Settings -> Size -> Position -> SelectedItem -> Item -> Svg Msg
canvasBottom settings ( svgWidth, svgHeight ) ( posX, posY ) selectedItem item =
    Svg.g
        []
        (case selectedItem of
            Just item_ ->
                if Item.getLineNo item_ == Item.getLineNo item then
                    [ canvasRect settings ( posX, posY ) ( svgWidth, svgHeight )
                    , inputView
                        { settings = settings
                        , fontSize =
                            Maybe.andThen (\f -> Just <| ItemSettings.getFontSize f) (Item.getItemSettings item)
                                |> Maybe.withDefault FontSize.lg
                        , position = ( posX, posY )
                        , size = ( svgWidth, settings.size.height )
                        , color = settings.color.label
                        , item = item_
                        }
                    , canvasText { settings = settings, svgWidth = svgWidth, position = ( posX, posY ), selectedItem = selectedItem, items = Item.unwrapChildren <| Item.getChildren item }
                    ]

                else
                    [ canvasRect settings ( posX, posY ) ( svgWidth, svgHeight )
                    , title settings ( posX + 20, posY + svgHeight - 25 ) item
                    , canvasText { settings = settings, svgWidth = svgWidth, position = ( posX, posY ), selectedItem = selectedItem, items = Item.unwrapChildren <| Item.getChildren item }
                    ]

            Nothing ->
                [ canvasRect settings ( posX, posY ) ( svgWidth, svgHeight )
                , title settings ( posX + 20, posY + svgHeight - 25 ) item
                , canvasText { settings = settings, svgWidth = svgWidth, position = ( posX, posY ), selectedItem = selectedItem, items = Item.unwrapChildren <| Item.getChildren item }
                ]
        )


canvasRect : Settings -> Position -> Size -> Svg msg
canvasRect settings ( posX, posY ) ( rectWidth, rectHeight ) =
    Svg.rect
        [ SvgAttr.width <| String.fromInt rectWidth
        , SvgAttr.height <| String.fromInt rectHeight
        , SvgAttr.stroke settings.color.line
        , SvgAttr.strokeWidth "10"
        , SvgAttr.x <| String.fromInt posX
        , SvgAttr.y <| String.fromInt posY
        , SvgAttr.class "ts-canvas"
        ]
        []


title : Settings -> Position -> Item -> Svg Msg
title settings ( posX, posY ) item =
    Svg.text_
        [ SvgAttr.x <| String.fromInt posX
        , SvgAttr.y <| String.fromInt <| posY + 14
        , SvgAttr.fontFamily <| Diagram.fontStyle settings
        , SvgAttr.fill
            (Item.getItemSettings item
                |> Maybe.withDefault ItemSettings.new
                |> ItemSettings.getForegroundColor
                |> Maybe.andThen (\c -> Just <| Color.toString c)
                |> Maybe.withDefault settings.color.label
            )
        , FontSize.svgFontSize FontSize.lg
        , SvgAttr.fontWeight "bold"
        , SvgAttr.class "select-none ts-title"
        , Events.onClickStopPropagation <| Select <| Just ( item, ( posX, posY + settings.size.height ) )
        ]
        [ Svg.text <| Item.getText item ]


canvasText : { settings : Settings, svgWidth : Int, position : Position, selectedItem : SelectedItem, items : Items } -> Svg Msg
canvasText { settings, svgWidth, position, selectedItem, items } =
    let
        ( posX, posY ) =
            position

        newSettings =
            settings |> settingsOfWidth.set (svgWidth - Constants.itemMargin * 2)
    in
    Svg.g []
        (Item.indexedMap
            (\i item ->
                card
                    { settings = newSettings
                    , position = ( posX + 16, posY + i * (settings.size.height + Constants.itemMargin) + Constants.itemMargin + 35 )
                    , selectedItem = selectedItem
                    , item = item
                    , canMove = False
                    }
            )
            items
        )


canvasImage : Settings -> Size -> Position -> Item -> Svg Msg
canvasImage settings ( svgWidth, svgHeight ) ( posX, posY ) item =
    Svg.g
        []
        [ canvasRect settings ( posX, posY ) ( svgWidth, svgHeight )
        , image ( Constants.itemWidth - 5, svgHeight )
            ( posX + 5, posY + 5 )
            (Item.getChildren item
                |> Item.unwrapChildren
                |> Item.map Item.getText
                |> List.head
                |> Maybe.withDefault ""
            )
        , title settings ( posX + 10, posY + 10 ) item
        ]


image : Size -> Position -> String -> Svg msg
image ( imageWidth, imageHeight ) ( posX, posY ) url =
    Svg.foreignObject
        [ SvgAttr.x <| String.fromInt posX
        , SvgAttr.y <| String.fromInt posY
        , SvgAttr.width <| String.fromInt imageWidth
        , SvgAttr.height <| String.fromInt imageHeight
        ]
        [ Html.img
            [ Attr.src url
            , Attr.style "width" <| String.fromInt imageWidth ++ "px"
            , Attr.style "height" <| String.fromInt imageHeight ++ "px"
            , Attr.style "object-fit" "cover"
            , SvgAttr.class "ts-image"
            ]
            []
        ]


node : Settings -> Position -> SelectedItem -> Item -> Svg Msg
node settings ( posX, posY ) selectedItem item =
    let
        ( color, _ ) =
            getItemColor settings item

        nodeWidth =
            settings.size.width

        view_ =
            Svg.g
                [ Events.onClickStopPropagation <| Select <| Just ( item, ( posX, posY + settings.size.height ) )
                , Diagram.dragStart (Diagram.ItemMove <| Diagram.ItemTarget item) False
                ]
                [ Svg.rect
                    [ SvgAttr.width <| String.fromInt nodeWidth
                    , SvgAttr.height <| String.fromInt <| settings.size.height - 1
                    , SvgAttr.x <| String.fromInt posX
                    , SvgAttr.y <| String.fromInt posY
                    , SvgAttr.fill settings.backgroundColor
                    ]
                    []
                , textNode settings ( posX, posY ) ( nodeWidth, settings.size.height ) color item
                ]
    in
    case selectedItem of
        Just item_ ->
            if Item.getLineNo item_ == Item.getLineNo item then
                Svg.g []
                    [ Svg.rect
                        [ SvgAttr.width <| String.fromInt nodeWidth
                        , SvgAttr.height <| String.fromInt <| settings.size.height - 1
                        , SvgAttr.x <| String.fromInt posX
                        , SvgAttr.y <| String.fromInt posY
                        , SvgAttr.strokeWidth "1"
                        , SvgAttr.stroke "transparent"
                        , SvgAttr.fill settings.backgroundColor
                        , SvgAttr.class "ts-node"
                        ]
                        []
                    , textNodeInput settings ( posX, posY ) ( nodeWidth, settings.size.height ) item_
                    ]

            else
                view_

        Nothing ->
            view_


rootTextNode : { settings : Settings, position : Position, selectedItem : SelectedItem, item : Item } -> Svg Msg
rootTextNode { settings, position, selectedItem, item } =
    let
        ( posX, posY ) =
            position

        borderColor =
            Item.getBackgroundColor item
                |> Maybe.andThen (\c -> Just <| Color.toString c)
                |> Maybe.withDefault settings.color.activity.backgroundColor

        textColor =
            Item.getForegroundColor item
                |> Maybe.andThen (\c -> Just <| Color.toString c)
                |> Maybe.withDefault settings.color.activity.color

        view_ =
            Svg.g
                [ Events.onClickStopPropagation <| Select <| Just ( item, ( posX, posY + settings.size.height ) )
                , Diagram.dragStart (Diagram.ItemMove <| Diagram.ItemTarget item) False
                ]
                [ Svg.rect
                    [ SvgAttr.width <| String.fromInt settings.size.width
                    , SvgAttr.height <| String.fromInt <| settings.size.height - 1
                    , SvgAttr.x <| String.fromInt posX
                    , SvgAttr.y <| String.fromInt posY
                    , SvgAttr.strokeWidth "2"
                    , SvgAttr.stroke borderColor
                    , SvgAttr.rx "32"
                    , SvgAttr.ry "32"
                    , SvgAttr.fill settings.backgroundColor
                    , SvgAttr.class "ts-node"
                    ]
                    []
                , textNode settings ( posX, posY ) ( settings.size.width, settings.size.height ) textColor item
                ]
    in
    case selectedItem of
        Just item_ ->
            if Item.getLineNo item_ == Item.getLineNo item then
                Svg.g []
                    [ Svg.rect
                        [ SvgAttr.width <| String.fromInt settings.size.width
                        , SvgAttr.height <| String.fromInt <| settings.size.height - 1
                        , SvgAttr.x <| String.fromInt posX
                        , SvgAttr.y <| String.fromInt posY
                        , SvgAttr.strokeWidth "2"
                        , SvgAttr.stroke borderColor
                        , SvgAttr.rx "32"
                        , SvgAttr.ry "32"
                        , SvgAttr.fill settings.backgroundColor
                        , SvgAttr.class "ts-node"
                        ]
                        []
                    , textNodeInput settings ( posX, posY ) ( settings.size.width, settings.size.height ) item_
                    ]

            else
                view_

        Nothing ->
            view_


textNode : Settings -> Position -> Size -> RgbColor -> Item -> Svg Msg
textNode settings ( posX, posY ) ( svgWidth, svgHeight ) colour item =
    Svg.foreignObject
        [ SvgAttr.x <| String.fromInt posX
        , SvgAttr.y <| String.fromInt posY
        , SvgAttr.width <| String.fromInt svgWidth
        , SvgAttr.height <| String.fromInt svgHeight
        , SvgAttr.fill colour
        , SvgAttr.color
            (Item.getForegroundColor item
                |> Maybe.withDefault Color.black
                |> Color.toString
            )
        , FontSize.svgFontSize FontSize.default
        , SvgAttr.class ".select-none"
        ]
        [ Html.div
            [ Attr.style "width" <| String.fromInt svgWidth ++ "px"
            , Attr.style "height" <| String.fromInt svgHeight ++ "px"
            , Attr.style "font-family" <| Diagram.fontStyle settings
            , Attr.style "word-wrap" "break-word"
            , Attr.style "display" "flex"
            , Attr.style "align-items" "center"
            , Attr.style "justify-content" "center"
            , Attr.class "ts-node"
            ]
            [ Html.div [ FontSize.htmlFontSize <| Item.getFontSize item ] [ Html.text <| Item.getText item ] ]
        ]


textNodeInput : Settings -> Position -> Size -> Item -> Svg Msg
textNodeInput settings ( posX, posY ) ( svgWidth, svgHeight ) item =
    Svg.foreignObject
        [ SvgAttr.x <| String.fromInt posX
        , SvgAttr.y <| String.fromInt posY
        , SvgAttr.width <| String.fromInt svgWidth
        , SvgAttr.height <| String.fromInt svgHeight
        ]
        [ Html.div
            [ Attr.style "background-color" "transparent"
            , Attr.style "width" (String.fromInt svgWidth ++ "px")
            , Attr.style "height" (String.fromInt svgHeight ++ "px")
            , Attr.style "display" "flex"
            , Attr.style "align-items" "center"
            , Attr.style "justify-content" "center"
            ]
            [ Html.input
                [ Attr.id "edit-item"
                , Attr.type_ "text"
                , Attr.style "font-family" <| Diagram.fontStyle settings
                , Attr.autofocus True
                , Attr.autocomplete False
                , Attr.style "padding" "8px 8px 8px 0"
                , Attr.style "font-family" <| Diagram.fontStyle settings
                , Attr.style "color"
                    (Item.getForegroundColor item
                        |> Maybe.withDefault Color.black
                        |> Color.toString
                    )
                , Attr.style "background-color" "transparent"
                , Attr.style "border" "none"
                , Attr.style "outline" "none"
                , Attr.style "width" (String.fromInt (svgWidth - 20) ++ "px")
                , FontSize.htmlFontSize <| Item.getFontSize item
                , Attr.style "margin-left" "2px"
                , Attr.style "margin-top" "2px"
                , Attr.value <| " " ++ String.trimLeft (Item.getText item)
                , onInput EditSelectedItem
                , Events.onEnter <| EndEditSelectedItem item
                ]
                []
            ]
        ]


grid : Settings -> Position -> SelectedItem -> Item -> Svg Msg
grid settings ( posX, posY ) selectedItem item =
    let
        ( forgroundColor, backgroundColor ) =
            getItemColor settings item

        view_ =
            Svg.g [ Events.onClickStopPropagation <| Select <| Just ( item, ( posX, posY + settings.size.height ) ) ]
                [ Svg.rect
                    [ SvgAttr.width <| String.fromInt settings.size.width
                    , SvgAttr.height <| String.fromInt <| settings.size.height - 1
                    , SvgAttr.x (String.fromInt posX)
                    , SvgAttr.y (String.fromInt posY)
                    , SvgAttr.fill backgroundColor
                    , SvgAttr.stroke settings.color.line
                    , SvgAttr.strokeWidth "1"
                    ]
                    []
                , text settings
                    ( posX, posY )
                    ( settings.size.width, settings.size.height )
                    forgroundColor
                    (Item.getItemSettings item |> Maybe.withDefault ItemSettings.new |> ItemSettings.getFontSize)
                    (Item.getText item)
                ]
    in
    case selectedItem of
        Just item_ ->
            if Item.getLineNo item_ == Item.getLineNo item then
                Svg.g []
                    [ Svg.rect
                        [ SvgAttr.width <| String.fromInt settings.size.width
                        , SvgAttr.height <| String.fromInt <| settings.size.height - 1
                        , SvgAttr.x (String.fromInt posX)
                        , SvgAttr.y (String.fromInt posY)
                        , SvgAttr.stroke "rgba(0, 0, 0, 0.1)"
                        , SvgAttr.fill backgroundColor
                        , SvgAttr.stroke settings.color.line
                        , SvgAttr.strokeWidth "1"
                        , SvgAttr.class "ts-grid"
                        ]
                        []
                    , inputView
                        { settings = settings
                        , fontSize = Item.getItemSettings item |> Maybe.withDefault ItemSettings.new |> ItemSettings.getFontSize
                        , position = ( posX, posY )
                        , size = ( settings.size.width, settings.size.height )
                        , color = forgroundColor
                        , item = item_
                        }
                    ]

            else
                view_

        Nothing ->
            view_
