module Views.Diagram.Views exposing (canvasBottomView, canvasImageView, canvasView, cardView, rectView, textView)

import Constants
import Events exposing (onClickStopPropagation, onKeyDown)
import Html exposing (div, img, input)
import Html.Attributes as Attr
import Html.Events exposing (onInput)
import Html5.DragDrop as DragDrop
import Maybe.Extra exposing (isJust)
import Models.Diagram exposing (Msg(..), Settings, fontStyle, settingsOfWidth)
import Models.Item as Item exposing (Item, ItemType(..), Items)
import Models.Position exposing (Position)
import Models.Size exposing (Size)
import String
import Svg exposing (Svg, foreignObject, g, image, rect, svg, text, text_)
import Svg.Attributes exposing (class, color, fill, fontFamily, fontSize, fontWeight, height, stroke, strokeWidth, style, width, x, xlinkHref, y)
import Utils


type alias RGB =
    String


cardView : Settings -> Position -> Maybe Item -> Item -> Svg Msg
cardView settings ( posX, posY ) selectedItem item =
    let
        ( color, backgroundColor ) =
            case item.itemType of
                Activities ->
                    ( settings.color.activity.color, settings.color.activity.backgroundColor )

                Tasks ->
                    ( settings.color.task.color, settings.color.task.backgroundColor )

                _ ->
                    ( settings.color.story.color, settings.color.story.backgroundColor )
    in
    if isJust selectedItem && ((selectedItem |> Maybe.withDefault Item.emptyItem |> .lineNo) == item.lineNo) then
        g []
            [ selectedRectView
                ( posX, posY )
                ( settings.size.width
                , settings.size.height - 1
                )
                backgroundColor
            , inputView settings Nothing ( posX, posY ) ( settings.size.width, settings.size.height ) ( color, backgroundColor ) (Maybe.withDefault Item.emptyItem selectedItem)
            ]

    else
        g
            [ onClickStopPropagation (ItemClick item)
            ]
            [ rectView
                ( posX, posY )
                ( settings.size.width
                , settings.size.height - 1
                )
                backgroundColor
            , textView settings ( posX, posY ) ( settings.size.width, settings.size.height ) color item.text
            , dropArea ( posX, posY ) ( settings.size.width, settings.size.height ) item
            ]


rectView : Position -> Size -> RGB -> Svg Msg
rectView ( posX, posY ) ( svgWidth, svgHeight ) color =
    rect
        [ width <| String.fromInt svgWidth
        , height <| String.fromInt svgHeight
        , x (String.fromInt posX)
        , y (String.fromInt posY)
        , fill color
        , style "filter:url(#shadow)"
        ]
        []


selectedRectView : Position -> Size -> RGB -> Svg Msg
selectedRectView ( posX, posY ) ( svgWidth, svgHeight ) color =
    rect
        [ width <| String.fromInt svgWidth
        , height <| String.fromInt svgHeight
        , x (String.fromInt posX)
        , y (String.fromInt posY)
        , strokeWidth "1"
        , stroke "#999"
        , fill color
        , style "filter:url(#shadow)"
        ]
        []


dropArea : Position -> Size -> Item -> Svg Msg
dropArea ( posX, posY ) ( svgWidth, svgHeight ) item =
    foreignObject
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
                ++ DragDrop.droppable DragDropMsg item.lineNo
            )
            []
        ]


inputView : Settings -> Maybe String -> Position -> Size -> ( RGB, RGB ) -> Item -> Svg Msg
inputView settings fontSize ( posX, posY ) ( svgWidth, svgHeight ) ( colour, backgroundColor ) item =
    foreignObject
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
                ++ DragDrop.draggable DragDropMsg item.lineNo
            )
            [ input
                [ Attr.id "edit-item"
                , Attr.type_ "text"
                , Attr.autofocus True
                , Attr.autocomplete False
                , Attr.style "padding" "8px 8px 8px 0"
                , Attr.style "font-family" (fontStyle settings)
                , Attr.style "color" colour
                , Attr.style "background-color" backgroundColor
                , Attr.style "border" "none"
                , Attr.style "outline" "none"
                , Attr.style "width" (String.fromInt (svgWidth - 20) ++ "px")
                , Attr.style "font-size" (Maybe.withDefault (item.text |> String.replace " " "" |> Utils.calcFontSize settings.size.width) fontSize ++ "px")
                , Attr.style "margin-left" "2px"
                , Attr.style "margin-top" "2px"
                , Attr.value <| " " ++ String.trimLeft item.text
                , onInput EditSelectedItem
                , onKeyDown <| EndEditSelectedItem item
                ]
                []
            ]
        ]


textView : Settings -> Position -> Size -> RGB -> String -> Svg Msg
textView settings ( posX, posY ) ( svgWidth, svgHeight ) colour textOrUrl =
    foreignObject
        [ x <| String.fromInt posX
        , y <| String.fromInt posY
        , width <| String.fromInt svgWidth
        , height <| String.fromInt svgHeight
        , fill colour
        , color colour
        , fontSize (textOrUrl |> String.replace " " "" |> Utils.calcFontSize settings.size.width)
        , class ".select-none"
        ]
        [ if Utils.isImageUrl textOrUrl then
            img
                [ Attr.style "object-fit" "cover"
                , Attr.style "width" (String.fromInt settings.size.width)
                , Attr.src textOrUrl
                ]
                []

          else
            div
                [ Attr.style "padding" "8px"
                , Attr.style "font-family" (fontStyle settings)
                , Attr.style "word-wrap" "break-word"
                ]
                [ Html.text textOrUrl ]
        ]


canvasView : Settings -> Size -> Position -> Maybe Item -> Item -> Svg Msg
canvasView settings ( svgWidth, svgHeight ) ( posX, posY ) selectedItem item =
    svg
        [ width <| String.fromInt svgWidth
        , height <| String.fromInt svgHeight
        , x <| String.fromInt posX
        , y <| String.fromInt posY
        , fill "transparent"
        ]
        [ canvasRectView settings ( svgWidth, svgHeight )
        , if isJust selectedItem && ((selectedItem |> Maybe.withDefault Item.emptyItem |> .lineNo) == item.lineNo) then
            inputView settings (Just "20") ( 0, 0 ) ( svgWidth, settings.size.height ) ( settings.color.label, "transparent" ) (Maybe.withDefault Item.emptyItem selectedItem)

          else
            titleView settings ( 20, 20 ) item
        , canvasTextView settings svgWidth ( 20, 35 ) selectedItem <| Item.unwrapChildren item.children
        ]


canvasBottomView : Settings -> Size -> Position -> Maybe Item -> Item -> Svg Msg
canvasBottomView settings ( svgWidth, svgHeight ) ( posX, posY ) selectedItem item =
    svg
        [ width <| String.fromInt svgWidth
        , height <| String.fromInt svgHeight
        , x <| String.fromInt posX
        , y <| String.fromInt posY
        , fill "transparent"
        ]
        [ canvasRectView settings ( svgWidth, svgHeight )
        , if isJust selectedItem && ((selectedItem |> Maybe.withDefault Item.emptyItem |> .lineNo) == item.lineNo) then
            inputView settings (Just <| String.fromInt <| svgHeight - 25) ( 0, 0 ) ( svgWidth, settings.size.height ) ( settings.color.label, "transparent" ) (Maybe.withDefault Item.emptyItem selectedItem)

          else
            titleView settings ( 20, svgHeight - 25 ) item
        , canvasTextView settings svgWidth ( 20, 35 ) selectedItem <| Item.unwrapChildren item.children
        ]


canvasRectView : Settings -> Size -> Svg Msg
canvasRectView settings ( rectWidth, rectHeight ) =
    rect
        [ width <| String.fromInt rectWidth
        , height <| String.fromInt rectHeight
        , stroke settings.color.line
        , strokeWidth "10"
        ]
        []


titleView : Settings -> Position -> Item -> Svg Msg
titleView settings ( posX, posY ) item =
    text_
        [ x <| String.fromInt posX
        , y <| String.fromInt <| posY + 14
        , fontFamily (fontStyle settings)
        , fill settings.color.label
        , fontSize "20"
        , fontWeight "bold"
        , class ".select-none"
        , onClickStopPropagation (ItemClick item)
        ]
        [ text item.text ]


canvasTextView : Settings -> Int -> Position -> Maybe Item -> Items -> Svg Msg
canvasTextView settings svgWidth ( posX, posY ) selectedItem items =
    let
        newSettings =
            settings |> settingsOfWidth.set (svgWidth - Constants.itemMargin * 2)
    in
    g []
        (Item.indexedMap
            (\i item ->
                cardView newSettings ( posX, posY + i * (settings.size.height + Constants.itemMargin) + Constants.itemMargin ) selectedItem item
            )
            items
        )


canvasImageView : Settings -> Size -> Position -> Item -> Svg Msg
canvasImageView settings ( svgWidth, svgHeight ) ( posX, posY ) item =
    let
        lines =
            Item.unwrapChildren item.children
                |> Item.map (\i -> i.text)
    in
    svg
        [ width <| String.fromInt svgWidth
        , height <| String.fromInt svgHeight
        , x <| String.fromInt posX
        , y <| String.fromInt posY
        ]
        [ canvasRectView settings ( svgWidth, svgHeight )
        , imageView ( Constants.itemWidth - 5, svgHeight ) ( 5, 5 ) (lines |> List.head |> Maybe.withDefault "")
        , titleView settings ( 10, 10 ) item
        ]


imageView : Size -> Position -> String -> Svg Msg
imageView ( imageWidth, imageHeight ) ( posX, posY ) url =
    svg
        [ width <| String.fromInt imageWidth
        , height <| String.fromInt imageHeight
        ]
        [ image
            [ x <| String.fromInt posX
            , y <| String.fromInt posY
            , width <| String.fromInt imageWidth
            , height <| String.fromInt imageHeight
            , xlinkHref url
            ]
            []
        ]
