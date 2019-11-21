module Views.Diagram.Views exposing (canvasImageView, canvasView)

import Constants exposing (..)
import Html exposing (div)
import Html.Attributes as Attr
import List.Extra exposing (last)
import Models.Diagram as Diagram exposing (Msg(..), Settings)
import Models.Item as Item exposing (Item, ItemType(..))
import String
import Svg exposing (Svg, foreignObject, g, image, rect, svg, text, text_)
import Svg.Attributes exposing (..)
import Svg.Events exposing (..)
import Utils


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
        [ rectView settings ( svgWidth, svgHeight )
        , titleView settings ( 10, 20 ) item.text
        , textView settings ( Constants.itemWidth - 13, svgHeight ) ( 10, 35 ) lines
        ]


rectView : Settings -> ( Int, Int ) -> Svg Msg
rectView settings ( rectWidth, rectHeight ) =
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


textView : Settings -> ( Int, Int ) -> ( Int, Int ) -> List String -> Svg Msg
textView settings ( textWidth, textHeight ) ( posX, posY ) lines =
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
        [ rectView settings ( svgWidth, svgHeight )
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
