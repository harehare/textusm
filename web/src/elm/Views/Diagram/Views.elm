module Views.Diagram.Views exposing (canvas, canvasBottom, canvasImage, card, grid, node, rootTextNode, text)

import Constants
import Data.Color as Color
import Data.FontSize as FontSize exposing (FontSize)
import Data.Item as Item exposing (Item, ItemType(..), Items)
import Data.ItemSettings as ItemSettings
import Data.Position as Position exposing (Position)
import Data.Size as Size exposing (Size)
import Events
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events exposing (onInput)
import Markdown
import Models.Diagram as Diagram exposing (Msg(..), SelectedItem, Settings, settingsOfWidth)
import String
import Svg exposing (Svg)
import Svg.Attributes as SvgAttr


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

        ( posX, posY ) =
            if ( offsetX, offsetY ) == Position.zero then
                position

            else
                position |> Tuple.mapBoth (\x -> x + offsetX) (\y -> y + offsetY)

        view_ =
            Svg.g
                [ Events.onClickStopPropagation <|
                    Select <|
                        Just ( item, ( posX, posY + settings.size.height + 8 ) )
                , if canMove then
                    Diagram.dragStart (Diagram.ItemMove <| Diagram.ItemTarget item) False

                  else
                    SvgAttr.style ""
                ]
                [ Svg.rect
                    [ SvgAttr.width <| String.fromInt settings.size.width
                    , SvgAttr.height <| String.fromInt <| settings.size.height - 1
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
                    ( settings.size.width, settings.size.height )
                    color
                    (Item.getItemSettings item |> Maybe.withDefault ItemSettings.new |> ItemSettings.getFontSize)
                    (Item.getText item)
                ]
    in
    case selectedItem of
        Just item_ ->
            if Item.getLineNo item_ == Item.getLineNo item then
                Svg.g []
                    [ Svg.rect
                        [ SvgAttr.width <| String.fromInt <| settings.size.width + 16
                        , SvgAttr.height <| String.fromInt <| settings.size.height + 16
                        , SvgAttr.x (String.fromInt <| posX - 8)
                        , SvgAttr.y (String.fromInt <| posY - 8)
                        , SvgAttr.rx "1"
                        , SvgAttr.ry "1"
                        , SvgAttr.fill "transparent"
                        , SvgAttr.stroke "#266b9a"
                        , SvgAttr.strokeWidth "1"
                        ]
                        []
                    , Svg.rect
                        [ SvgAttr.width <| String.fromInt <| settings.size.width + 4
                        , SvgAttr.height <| String.fromInt <| settings.size.height + 4
                        , SvgAttr.x (String.fromInt <| posX - 2)
                        , SvgAttr.y (String.fromInt <| posY - 2)
                        , SvgAttr.rx "1"
                        , SvgAttr.ry "1"
                        , SvgAttr.fill backgroundColor
                        , SvgAttr.style "filter:url(#shadow)"
                        ]
                        []
                    , inputView
                        { settings = settings
                        , fontSize = Item.getItemSettings item |> Maybe.withDefault ItemSettings.new |> ItemSettings.getFontSize
                        , position = ( posX, posY )
                        , size = ( settings.size.width, settings.size.height )
                        , color = color
                        , backgroundColor = backgroundColor
                        , item = item_
                        }
                    ]

            else
                view_

        Nothing ->
            view_


inputView :
    { settings : Settings
    , fontSize : FontSize
    , position : Position
    , size : Size
    , color : RgbColor
    , backgroundColor : RgbColor
    , item : Item
    }
    -> Svg Msg
inputView { settings, fontSize, position, size, color, backgroundColor, item } =
    Svg.foreignObject
        [ SvgAttr.x <| String.fromInt <| Position.getX position
        , SvgAttr.y <| String.fromInt <| Position.getY position
        , SvgAttr.width <| String.fromInt <| Size.getWidth size
        , SvgAttr.height <| String.fromInt <| Size.getHeight size
        ]
        [ Html.div
            [ Attr.style "background-color" backgroundColor
            , Attr.style "width" (String.fromInt (Size.getWidth size) ++ "px")
            , Attr.style "height" (String.fromInt (Size.getHeight size) ++ "px")
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
                                |> Maybe.withDefault FontSize.fontSize20
                        , position = ( posX, posY )
                        , size = ( svgWidth, settings.size.height )
                        , color =
                            Item.getItemSettings item
                                |> Maybe.withDefault ItemSettings.new
                                |> ItemSettings.getForegroundColor
                                |> Maybe.andThen (\c -> Just <| Color.toString c)
                                |> Maybe.withDefault settings.color.label
                        , backgroundColor = "transparent"
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
                                |> Maybe.withDefault FontSize.fontSize20
                        , position = ( posX, posY )
                        , size = ( svgWidth, settings.size.height )
                        , color = settings.color.label
                        , backgroundColor = "transparent"
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
        , FontSize.svgFontSize FontSize.fontSize20
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
                        , backgroundColor = "transparent"
                        , item = item_
                        }
                    ]

            else
                view_

        Nothing ->
            view_
