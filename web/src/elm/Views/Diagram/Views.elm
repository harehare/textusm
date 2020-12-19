module Views.Diagram.Views exposing (canvas, canvasBottom, canvasImage, card, grid, node, rootTextNode, text)

import Constants
import Data.Color as Color
import Data.Item as Item exposing (Item, ItemType(..), Items)
import Data.ItemSettings as ItemSettings
import Data.Position as Position exposing (Position)
import Data.Size as Size exposing (Size)
import Events exposing (onClickStopPropagation, onKeyDown)
import Html as Html exposing (Html, div, img, input)
import Html.Attributes as Attr
import Html.Events exposing (onInput)
import Html5.DragDrop as DragDrop
import Markdown
import Maybe.Extra exposing (isJust)
import Models.Diagram as Diagram exposing (Msg(..), SelectedItem, Settings, fontStyle, getTextColor, settingsOfWidth)
import String
import Svg exposing (Svg)
import Svg.Attributes exposing (class, color, fill, fillOpacity, fontFamily, fontSize, fontWeight, height, rx, ry, stroke, strokeWidth, style, width, x, y)


type alias RgbColor =
    String


draggingStyle : Bool -> Svg.Attribute msg
draggingStyle isDragging =
    if isDragging then
        fillOpacity "0.5"

    else
        fillOpacity "1.0"


draggingHtmlStyle : Bool -> Html.Attribute msg
draggingHtmlStyle isDragging =
    if isDragging then
        Attr.style "opacity" "0.6"

    else
        Attr.style "opacity" "1.0"


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
            ( settings.color.activity.backgroundColor, Color.toString b )

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


card : { settings : Settings, position : Position, selectedItem : SelectedItem, item : Item } -> Svg Msg
card { settings, position, selectedItem, item } =
    let
        ( color, backgroundColor ) =
            getItemColor settings item

        ( posX, posY ) =
            position

        view_ =
            Svg.g [ onClickStopPropagation <| Select <| Just ( item, ( posX, posY + settings.size.height + 8 ) ) ]
                [ Svg.rect
                    [ width <| String.fromInt settings.size.width
                    , height <| String.fromInt <| settings.size.height - 1
                    , x <| String.fromInt posX
                    , y <| String.fromInt posY
                    , fill backgroundColor
                    , rx "1"
                    , ry "1"
                    , style "filter:url(#shadow)"
                    ]
                    []
                , text settings ( posX, posY ) ( settings.size.width, settings.size.height ) color (Item.getText item)
                , if isJust selectedItem then
                    dropArea ( posX, posY ) ( settings.size.width, settings.size.height ) item

                  else
                    Svg.g [] []
                ]
    in
    case selectedItem of
        Just ( item_, isDragging ) ->
            if Item.getLineNo item_ == Item.getLineNo item then
                Svg.g []
                    [ Svg.rect
                        [ width <| String.fromInt <| settings.size.width + 4
                        , height <| String.fromInt <| settings.size.height + 4
                        , x (String.fromInt <| posX - 2)
                        , y (String.fromInt <| posY - 2)
                        , strokeWidth "3"
                        , stroke "#1d2f4b"
                        , rx "1"
                        , ry "1"
                        , fill backgroundColor
                        , style "filter:url(#shadow)"
                        , draggingStyle isDragging
                        ]
                        []
                    , inputView
                        { settings = settings
                        , fontSize = Nothing
                        , inputStyle = draggingHtmlStyle isDragging
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


dropArea : Position -> Size -> Item -> Svg Msg
dropArea ( posX, posY ) ( svgWidth, svgHeight ) item =
    Svg.foreignObject
        [ x <| String.fromInt posX
        , y <| String.fromInt posY
        , width <| String.fromInt svgWidth
        , height <| String.fromInt svgHeight
        ]
        [ div
            ([ Attr.style "background-color" "transparent"
             , Attr.style "width" (String.fromInt svgWidth ++ "px")
             , Attr.style "height" (String.fromInt svgHeight ++ "px")
             ]
                ++ DragDrop.droppable DragDropMsg (Item.getLineNo item)
            )
            []
        ]


inputView :
    { settings : Settings
    , fontSize : Maybe String
    , inputStyle : Html.Attribute Msg
    , position : Position
    , size : Size
    , color : RgbColor
    , backgroundColor : RgbColor
    , item : Item
    }
    -> Svg Msg
inputView { settings, fontSize, inputStyle, position, size, color, backgroundColor, item } =
    Svg.foreignObject
        [ x <| String.fromInt <| Position.getX position
        , y <| String.fromInt <| Position.getY position
        , width <| String.fromInt <| Size.getWidth size
        , height <| String.fromInt <| Size.getHeight size
        ]
        [ div
            ([ Attr.style "background-color" backgroundColor
             , Attr.style "width" (String.fromInt (Size.getWidth size) ++ "px")
             , Attr.style "height" (String.fromInt (Size.getHeight size) ++ "px")
             , inputStyle
             ]
                ++ DragDrop.draggable DragDropMsg (Item.getLineNo item)
            )
            [ input
                [ Attr.id "edit-item"
                , Attr.type_ "text"
                , Attr.autofocus True
                , Attr.autocomplete False
                , Attr.style "padding" "8px 8px 8px 0"
                , Attr.style "font-family" (fontStyle settings)
                , Attr.style "color" color
                , Attr.style "background-color" "transparent"
                , Attr.style "border" "none"
                , Attr.style "outline" "none"
                , Attr.style "width" (String.fromInt (Size.getWidth size - 20) ++ "px")
                , Attr.style "font-size" <| Maybe.withDefault Constants.fontSize fontSize ++ "px"
                , Attr.style "margin-left" "2px"
                , Attr.style "margin-top" "2px"
                , Attr.value <| " " ++ String.trimLeft (Item.getText item)
                , onInput EditSelectedItem
                , onKeyDown <| EndEditSelectedItem item
                ]
                []
            ]
        ]


text : Settings -> Position -> Size -> RgbColor -> String -> Svg Msg
text settings ( posX, posY ) ( svgWidth, svgHeight ) colour cardText =
    if Item.isMarkdown cardText then
        Svg.foreignObject
            [ x <| String.fromInt posX
            , y <| String.fromInt posY
            , width <| String.fromInt svgWidth
            , height <| String.fromInt svgHeight
            , fill colour
            , color colour
            , fontSize Constants.fontSize
            , class ".select-none"
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
            [ x <| String.fromInt posX
            , y <| String.fromInt posY
            , width <| String.fromInt svgWidth
            , height <| String.fromInt svgHeight
            , fill colour
            , color colour
            , fontSize Constants.fontSize
            , class ".select-none"
            ]
            [ div
                [ Attr.style "padding" "8px"
                , Attr.style "font-family" (fontStyle settings)
                , Attr.style "word-wrap" "break-word"
                ]
                [ Html.text cardText ]
            ]

    else
        Svg.text_
            [ x <| String.fromInt <| posX + 6
            , y <| String.fromInt <| posY + 24
            , width <| String.fromInt svgWidth
            , height <| String.fromInt svgHeight
            , fill colour
            , color colour
            , fontFamily (fontStyle settings)
            , fontSize <| Constants.fontSize
            , class ".select-none"
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
            Just ( item_, isDragging ) ->
                if Item.getLineNo item_ == Item.getLineNo item then
                    [ canvasRect settings (draggingStyle isDragging) ( posX, posY ) ( svgWidth, svgHeight )
                    , inputView
                        { settings = settings
                        , fontSize = Just "20"
                        , inputStyle = draggingHtmlStyle isDragging
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
                    [ canvasRect settings (draggingStyle isDragging) ( posX, posY ) ( svgWidth, svgHeight )
                    , title settings ( posX + 20, posY + 20 ) item
                    , canvasText { settings = settings, svgWidth = svgWidth, position = ( posX, posY ), selectedItem = selectedItem, items = Item.unwrapChildren <| Item.getChildren item }
                    ]

            Nothing ->
                [ canvasRect settings (draggingStyle False) ( posX, posY ) ( svgWidth, svgHeight )
                , title settings ( posX + 20, posY + 20 ) item
                , canvasText { settings = settings, svgWidth = svgWidth, position = ( posX, posY ), selectedItem = selectedItem, items = Item.unwrapChildren <| Item.getChildren item }
                ]
        )


canvasBottom : Settings -> Size -> Position -> SelectedItem -> Item -> Svg Msg
canvasBottom settings ( svgWidth, svgHeight ) ( posX, posY ) selectedItem item =
    Svg.g
        []
        (case selectedItem of
            Just ( item_, isDragging ) ->
                if Item.getLineNo item_ == Item.getLineNo item then
                    [ canvasRect settings (draggingStyle isDragging) ( posX, posY ) ( svgWidth, svgHeight )
                    , inputView
                        { settings = settings
                        , fontSize = Just <| String.fromInt <| svgHeight - 25
                        , inputStyle = draggingHtmlStyle isDragging
                        , position = ( posX, posY )
                        , size = ( svgWidth, settings.size.height )
                        , color = settings.color.label
                        , backgroundColor = "transparent"
                        , item = item_
                        }
                    , canvasText { settings = settings, svgWidth = svgWidth, position = ( posX, posY ), selectedItem = selectedItem, items = Item.unwrapChildren <| Item.getChildren item }
                    ]

                else
                    [ canvasRect settings (draggingStyle isDragging) ( posX, posY ) ( svgWidth, svgHeight )
                    , title settings ( posX + 20, posY + svgHeight - 25 ) item
                    , canvasText { settings = settings, svgWidth = svgWidth, position = ( posX, posY ), selectedItem = selectedItem, items = Item.unwrapChildren <| Item.getChildren item }
                    ]

            Nothing ->
                [ canvasRect settings (draggingStyle False) ( posX, posY ) ( svgWidth, svgHeight )
                , title settings ( posX + 20, posY + svgHeight - 25 ) item
                , canvasText { settings = settings, svgWidth = svgWidth, position = ( posX, posY ), selectedItem = selectedItem, items = Item.unwrapChildren <| Item.getChildren item }
                ]
        )


canvasRect : Settings -> Svg.Attribute msg -> Position -> Size -> Svg msg
canvasRect settings rectStyle ( posX, posY ) ( rectWidth, rectHeight ) =
    Svg.rect
        [ width <| String.fromInt rectWidth
        , height <| String.fromInt rectHeight
        , stroke settings.color.line
        , strokeWidth "10"
        , rectStyle
        , x <| String.fromInt posX
        , y <| String.fromInt posY
        ]
        []


title : Settings -> Position -> Item -> Svg Msg
title settings ( posX, posY ) item =
    Svg.text_
        [ x <| String.fromInt posX
        , y <| String.fromInt <| posY + 14
        , fontFamily <| fontStyle settings
        , fill
            (Item.getItemSettings item
                |> Maybe.withDefault ItemSettings.new
                |> ItemSettings.getForegroundColor
                |> Maybe.andThen (\c -> Just <| Color.toString c)
                |> Maybe.withDefault settings.color.label
            )
        , fontSize "20"
        , fontWeight "bold"
        , class ".select-none"
        , onClickStopPropagation <| Select <| Just ( item, ( posX, posY + settings.size.height ) )
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
                    }
            )
            items
        )


canvasImage : Settings -> Size -> Position -> Item -> Svg Msg
canvasImage settings ( svgWidth, svgHeight ) ( posX, posY ) item =
    Svg.g
        []
        [ canvasRect settings (draggingStyle False) ( posX, posY ) ( svgWidth, svgHeight )
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
        [ x <| String.fromInt posX
        , y <| String.fromInt posY
        , width <| String.fromInt imageWidth
        , height <| String.fromInt imageHeight
        ]
        [ img
            [ Attr.src url
            , Attr.style "width" <| String.fromInt imageWidth ++ "px"
            , Attr.style "height" <| String.fromInt imageHeight ++ "px"
            , Attr.style "object-fit" "cover"
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
            Svg.g [ onClickStopPropagation <| Select <| Just ( item, ( posX, posY + settings.size.height ) ) ]
                [ Svg.rect
                    [ width <| String.fromInt nodeWidth
                    , height <| String.fromInt <| settings.size.height - 1
                    , x <| String.fromInt posX
                    , y <| String.fromInt posY
                    , fill settings.backgroundColor
                    ]
                    []
                , textNode settings ( posX, posY ) ( nodeWidth, settings.size.height ) color item
                , if isJust selectedItem then
                    dropArea ( posX, posY ) ( nodeWidth, settings.size.height ) item

                  else
                    Svg.g [] []
                ]
    in
    case selectedItem of
        Just ( item_, isDragging ) ->
            if Item.getLineNo item_ == Item.getLineNo item then
                Svg.g []
                    [ Svg.rect
                        [ width <| String.fromInt nodeWidth
                        , height <| String.fromInt <| settings.size.height - 1
                        , x <| String.fromInt posX
                        , y <| String.fromInt posY
                        , strokeWidth "1"
                        , stroke "rgba(0, 0, 0, 0.1)"
                        , fill settings.backgroundColor
                        , draggingStyle isDragging
                        ]
                        []
                    , textNodeInput settings ( posX, posY ) ( nodeWidth, settings.size.height ) item_
                    ]

            else
                view_

        Nothing ->
            view_


rootTextNode : Settings -> Position -> SelectedItem -> Item -> Svg Msg
rootTextNode settings ( posX, posY ) selectedItem item =
    let
        borderColor =
            Item.getBackgroundColor item
                |> Maybe.andThen (\c -> Just <| Color.toString c)
                |> Maybe.withDefault settings.color.activity.backgroundColor

        textColor =
            Item.getForegroundColor item
                |> Maybe.andThen (\c -> Just <| Color.toString c)
                |> Maybe.withDefault settings.color.activity.color

        view_ =
            Svg.g [ onClickStopPropagation <| Select <| Just ( item, ( posX, posY + settings.size.height ) ) ]
                [ Svg.rect
                    [ width <| String.fromInt settings.size.width
                    , height <| String.fromInt <| settings.size.height - 1
                    , x <| String.fromInt posX
                    , y <| String.fromInt posY
                    , strokeWidth "2"
                    , stroke borderColor
                    , rx "32"
                    , ry "32"
                    , fill settings.backgroundColor
                    , draggingStyle False
                    ]
                    []
                , textNode settings ( posX, posY ) ( settings.size.width, settings.size.height ) textColor item
                , if isJust selectedItem then
                    dropArea ( posX, posY ) ( settings.size.width, settings.size.height ) item

                  else
                    Svg.g [] []
                ]
    in
    case selectedItem of
        Just ( item_, isDragging ) ->
            if Item.getLineNo item_ == Item.getLineNo item then
                Svg.g []
                    [ Svg.rect
                        [ width <| String.fromInt settings.size.width
                        , height <| String.fromInt <| settings.size.height - 1
                        , x <| String.fromInt posX
                        , y <| String.fromInt posY
                        , strokeWidth "2"
                        , stroke borderColor
                        , rx "32"
                        , ry "32"
                        , fill settings.backgroundColor
                        , draggingStyle isDragging
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
        [ x <| String.fromInt posX
        , y <| String.fromInt posY
        , width <| String.fromInt svgWidth
        , height <| String.fromInt svgHeight
        , fill colour
        , color
            (Item.getForegroundColor item
                |> Maybe.withDefault Color.black
                |> Color.toString
            )
        , fontSize Constants.fontSize
        , class ".select-none"
        ]
        [ div
            [ Attr.style "width" <| String.fromInt svgWidth ++ "px"
            , Attr.style "height" <| String.fromInt svgHeight ++ "px"
            , Attr.style "font-family" <| fontStyle settings
            , Attr.style "word-wrap" "break-word"
            , Attr.style "display" "flex"
            , Attr.style "align-items" "center"
            , Attr.style "justify-content" "center"
            ]
            [ div [ Attr.style "font-size" "14px" ] [ Html.text <| Item.getText item ] ]
        ]


textNodeInput : Settings -> Position -> Size -> Item -> Svg Msg
textNodeInput settings ( posX, posY ) ( svgWidth, svgHeight ) item =
    Svg.foreignObject
        [ x <| String.fromInt posX
        , y <| String.fromInt posY
        , width <| String.fromInt svgWidth
        , height <| String.fromInt svgHeight
        ]
        [ div
            ([ Attr.style "background-color" "transparent"
             , Attr.style "width" (String.fromInt svgWidth ++ "px")
             , Attr.style "height" (String.fromInt svgHeight ++ "px")
             , Attr.style "display" "flex"
             , Attr.style "align-items" "center"
             , Attr.style "justify-content" "center"
             ]
                ++ DragDrop.draggable DragDropMsg (Item.getLineNo item)
            )
            [ input
                [ Attr.id "edit-item"
                , Attr.type_ "text"
                , Attr.autofocus True
                , Attr.autocomplete False
                , Attr.style "padding" "8px 8px 8px 0"
                , Attr.style "font-family" (fontStyle settings)
                , Attr.style "color"
                    (Item.getForegroundColor item
                        |> Maybe.withDefault Color.black
                        |> Color.toString
                    )
                , Attr.style "background-color" "transparent"
                , Attr.style "border" "none"
                , Attr.style "outline" "none"
                , Attr.style "width" (String.fromInt (svgWidth - 20) ++ "px")
                , Attr.style "font-size" "14px"
                , Attr.style "margin-left" "2px"
                , Attr.style "margin-top" "2px"
                , Attr.value <| " " ++ String.trimLeft (Item.getText item)
                , onInput EditSelectedItem
                , onKeyDown <| EndEditSelectedItem item
                ]
                []
            ]
        ]


grid : Settings -> Position -> SelectedItem -> Item -> Svg Msg
grid settings ( posX, posY ) selectedItem item =
    let
        view_ =
            Svg.g [ onClickStopPropagation <| Select <| Just ( item, ( posX, posY + settings.size.height ) ) ]
                [ Svg.rect
                    [ width <| String.fromInt settings.size.width
                    , height <| String.fromInt <| settings.size.height - 1
                    , x (String.fromInt posX)
                    , y (String.fromInt posY)
                    , fill "transparent"
                    , stroke settings.color.line
                    , strokeWidth "3"
                    ]
                    []
                , text settings ( posX, posY ) ( settings.size.width, settings.size.height ) (Diagram.getTextColor settings.color) (Item.getText item)
                , if isJust selectedItem then
                    dropArea ( posX, posY ) ( settings.size.width, settings.size.height ) item

                  else
                    Svg.g [] []
                ]
    in
    case selectedItem of
        Just ( item_, isDragging ) ->
            if Item.getLineNo item_ == Item.getLineNo item then
                Svg.g []
                    [ Svg.rect
                        [ width <| String.fromInt settings.size.width
                        , height <| String.fromInt <| settings.size.height - 1
                        , x (String.fromInt posX)
                        , y (String.fromInt posY)
                        , strokeWidth "3"
                        , stroke "rgba(0, 0, 0, 0.1)"
                        , fill "transparent"
                        , stroke settings.color.line
                        , strokeWidth "3"
                        , draggingStyle isDragging
                        ]
                        []
                    , inputView
                        { settings = settings
                        , fontSize = Nothing
                        , inputStyle = draggingHtmlStyle isDragging
                        , position = ( posX, posY )
                        , size = ( settings.size.width, settings.size.height )
                        , color = Diagram.getTextColor settings.color
                        , backgroundColor = "transparent"
                        , item = item_
                        }
                    ]

            else
                view_

        Nothing ->
            view_
