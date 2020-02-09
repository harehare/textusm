module Views.Diagram.Views exposing (canvasImageView, canvasView, cardView, rectView, textView)

import Constants
import Events exposing (onKeyDown)
import Html exposing (div, img, input)
import Html.Attributes as Attr
import Html.Events exposing (onBlur, onInput)
import List.Extra exposing (last)
import Maybe.Extra exposing (isJust)
import Models.Diagram as Diagram exposing (Msg(..), Settings)
import Models.Item as Item exposing (Item, ItemType(..))
import String
import Svg exposing (Svg, foreignObject, g, image, rect, svg, text, text_)
import Svg.Attributes exposing (class, color, fill, fontFamily, fontSize, fontWeight, height, stroke, strokeWidth, width, x, xlinkHref, y)
import Svg.Events exposing (onClick)
import Utils


cardView : Settings -> ( Int, Int ) -> Maybe Item -> Item -> Svg Msg
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
    svg
        [ width (String.fromInt settings.size.width)
        , height (String.fromInt settings.size.height)
        , x (String.fromInt posX)
        , y (String.fromInt posY)
        ]
        [ if isJust selectedItem && ((selectedItem |> Maybe.withDefault Item.emptyItem |> .lineNo) == item.lineNo) then
            inputView settings ( 0, 0 ) ( settings.size.width, settings.size.height ) ( color, backgroundColor ) (Maybe.withDefault Item.emptyItem selectedItem)

          else
            g
                [ onClick (ItemClick item)
                ]
                [ rectView
                    ( settings.size.width
                    , settings.size.height - 1
                    )
                    backgroundColor
                , textView settings ( 0, 0 ) ( settings.size.width, settings.size.height ) color item.text
                ]
        ]


rectView : ( Int, Int ) -> String -> Svg Msg
rectView ( svgWidth, svgHeight ) color =
    rect
        [ width <| String.fromInt svgWidth
        , height <| String.fromInt svgHeight
        , fill color
        , stroke "rgba(192,192,192,0.5)"
        ]
        []


inputView : Settings -> ( Int, Int ) -> ( Int, Int ) -> ( String, String ) -> Item -> Svg Msg
inputView settings ( posX, posY ) ( svgWidth, svgHeight ) ( colour, backgroundColor ) item =
    foreignObject
        [ x <| String.fromInt posX
        , y <| String.fromInt posY
        , width <| String.fromInt svgWidth
        , height <| String.fromInt svgHeight
        ]
        [ div
            [ Attr.style "background-color" backgroundColor
            , Attr.style "position" "relative"
            , Attr.style "width" (String.fromInt svgWidth ++ "px")
            , Attr.style "height" (String.fromInt svgHeight ++ "px")
            ]
            [ input
                [ Attr.id "edit-item"
                , Attr.type_ "text"
                , Attr.style "padding" "8px"
                , Attr.style "position" "absolute"
                , Attr.style "top" "0"
                , Attr.style "font-family" ("'" ++ settings.font ++ "', sans-serif")
                , Attr.style "color" colour
                , Attr.style "background-color" backgroundColor
                , Attr.style "border" "none"
                , Attr.style "outline" "none"
                , Attr.style "width" (String.fromInt (svgWidth - 16) ++ "px")
                , Attr.style "font-family" settings.font
                , Attr.style "font-size" ((item.text |> String.replace " " "" |> Utils.calcFontSize settings.size.width) ++ "px")
                , Attr.value <| String.trim item.text
                , onBlur DeselectItem
                , onInput EditSelectedItem
                , onKeyDown <| EndEditSelectedItem item
                ]
                []
            ]
        ]


textView : Settings -> ( Int, Int ) -> ( Int, Int ) -> String -> String -> Svg Msg
textView settings ( posX, posY ) ( svgWidth, svgHeight ) colour textOrUrl =
    foreignObject
        [ x <| String.fromInt posX
        , y <| String.fromInt posY
        , width <| String.fromInt svgWidth
        , height <| String.fromInt svgHeight
        , fill colour
        , color colour
        , fontSize (textOrUrl |> String.replace " " "" |> Utils.calcFontSize settings.size.width)
        , fontFamily settings.font
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
                , Attr.style "font-family" ("'" ++ settings.font ++ "', sans-serif")
                , Attr.style "word-wrap" "break-word"
                ]
                [ Html.text textOrUrl ]
        ]


canvasView : Settings -> ( Int, Int ) -> ( Int, Int ) -> Item -> Svg Msg
canvasView settings ( svgWidth, svgHeight ) ( posX, posY ) item =
    let
        lines =
            Item.unwrapChildren item.children
                |> List.map (\i -> i.text)
    in
    svg
        [ width <| String.fromInt svgWidth
        , height <| String.fromInt svgHeight
        , x <| String.fromInt posX
        , y <| String.fromInt posY
        , fill "transparent"
        ]
        [ canvasRectView settings ( svgWidth, svgHeight )
        , titleView settings ( 10, 20 ) item.text
        , canvasTextView settings ( Constants.itemWidth - 13, svgHeight ) ( 10, 35 ) lines
        ]


canvasRectView : Settings -> ( Int, Int ) -> Svg Msg
canvasRectView settings ( rectWidth, rectHeight ) =
    rect
        [ width <| String.fromInt rectWidth
        , height <| String.fromInt rectHeight
        , stroke settings.color.line
        , strokeWidth "10"
        ]
        []


titleView : Settings -> ( Int, Int ) -> String -> Svg Msg
titleView settings ( posX, posY ) title =
    text_
        [ x <| String.fromInt posX
        , y <| String.fromInt <| posY + 14
        , fontFamily settings.font
        , fill settings.color.label
        , fontSize "20"
        , fontWeight "bold"
        , class ".select-none"
        ]
        [ text title ]


canvasTextView : Settings -> ( Int, Int ) -> ( Int, Int ) -> List String -> Svg Msg
canvasTextView settings ( textWidth, textHeight ) ( posX, posY ) lines =
    let
        maxLine =
            List.sortBy String.length lines
                |> last
                |> Maybe.withDefault ""
    in
    foreignObject
        [ x <| String.fromInt posX
        , y <| String.fromInt posY
        , width <| String.fromInt textWidth
        , height <| String.fromInt textHeight
        , color settings.color.label
        , fontSize <| Utils.calcFontSize textWidth maxLine
        , fontFamily settings.font
        , class ".select-none"
        ]
        (lines
            |> List.map
                (\line ->
                    div
                        [ Attr.style "font-family" ("'" ++ settings.font ++ "', sans-serif")
                        , Attr.style "word-wrap" "break-word"
                        , Attr.style "padding" "0 8px 8px 0"
                        , Attr.style "color" <| Diagram.getTextColor settings.color
                        ]
                        [ Html.text line ]
                )
        )


canvasImageView : Settings -> ( Int, Int ) -> ( Int, Int ) -> Item -> Svg Msg
canvasImageView settings ( svgWidth, svgHeight ) ( posX, posY ) item =
    let
        lines =
            Item.unwrapChildren item.children
                |> List.map (\i -> i.text)
    in
    svg
        [ width <| String.fromInt svgWidth
        , height <| String.fromInt svgHeight
        , x <| String.fromInt posX
        , y <| String.fromInt posY
        ]
        [ canvasRectView settings ( svgWidth, svgHeight )
        , imageView ( Constants.itemWidth - 5, svgHeight ) ( 5, 5 ) (lines |> List.head |> Maybe.withDefault "")
        , titleView settings ( 10, 10 ) item.text
        ]


imageView : ( Int, Int ) -> ( Int, Int ) -> String -> Svg Msg
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
