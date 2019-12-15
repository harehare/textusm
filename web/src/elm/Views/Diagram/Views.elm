module Views.Diagram.Views exposing (canvasImageView, canvasView, cardView, textView)

import Constants exposing (..)
import Html exposing (div, img)
import Html.Attributes as Attr
import Json.Decode as D
import List.Extra exposing (last)
import Models.Diagram as Diagram exposing (Msg(..), Settings)
import Models.Item as Item exposing (Item, ItemType(..))
import String
import Svg exposing (Svg, foreignObject, g, image, rect, svg, text, text_)
import Svg.Attributes exposing (..)
import Svg.Events exposing (..)
import Utils


cardView : Settings -> ( Int, Int ) -> Item -> Svg Msg
cardView settings ( posX, posY ) item =
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
        , onClick (ItemClick item)
        , stopPropagationOn "dblclick" (D.map (\d -> ( d, True )) (D.succeed (ItemDblClick item)))
        ]
        [ rectView
            (String.fromInt settings.size.width)
            (String.fromInt (settings.size.height - 1))
            backgroundColor
        , textView settings "0" "0" color item.text
        ]


rectView : String -> String -> String -> Svg Msg
rectView svgWidth svgHeight color =
    rect
        [ width svgWidth
        , height svgHeight
        , fill color
        , stroke "rgba(192,192,192,0.5)"
        ]
        []


textView : Settings -> String -> String -> String -> String -> Svg Msg
textView settings posX posY c t =
    foreignObject
        [ x posX
        , y posY
        , width (String.fromInt settings.size.width)
        , height (String.fromInt settings.size.height)
        , fill c
        , color c
        , fontSize (t |> String.replace " " "" |> Utils.calcFontSize settings.size.width)
        , fontFamily settings.font
        , class ".select-none"
        ]
        [ if Utils.isImageUrl t then
            img
                [ Attr.style "object-fit" "cover"
                , Attr.style "width" (String.fromInt settings.size.width)
                , Attr.src t
                ]
                []

          else
            div
                [ Attr.style "padding" "8px"
                , Attr.style "font-family" ("'" ++ settings.font ++ "', sans-serif")
                , Attr.style "word-wrap" "break-word"
                ]
                [ Html.text t ]
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
