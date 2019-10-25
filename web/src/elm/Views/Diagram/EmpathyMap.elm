module Views.Diagram.EmpathyMap exposing (view)

import Constants exposing (..)
import Html exposing (div, img)
import Html.Attributes as Attr
import List.Extra exposing (getAt, last)
import Models.Diagram as Diagram exposing (Model, Msg(..), Settings)
import Models.Item as Item exposing (Item, ItemType(..))
import String
import Svg exposing (..)
import Svg.Attributes exposing (..)
import Svg.Events exposing (..)
import Utils


type Direction
    = Top
    | Bottom


view : Model -> Svg Msg
view model =
    let
        itemHeight =
            Basics.max Constants.largeItemHeight (14 * (List.maximum model.countByTasks |> Maybe.withDefault 0))
    in
    g
        [ transform
            ("translate("
                ++ String.fromInt
                    (if isInfinite <| toFloat <| model.x then
                        0

                     else
                        model.x
                    )
                ++ ","
                ++ String.fromInt
                    (if isInfinite <| toFloat <| model.y then
                        0

                     else
                        model.y
                    )
                ++ ")"
            )
        , fill model.settings.backgroundColor
        ]
        [ -- SAYS
          canvasView model.settings
            Top
            Constants.largeItemWidth
            itemHeight
            "0"
            "0"
            (model.items
                |> getAt 1
                |> Maybe.withDefault Item.emptyItem
            )

        -- THINKS
        , canvasView model.settings
            Top
            Constants.largeItemWidth
            itemHeight
            (String.fromInt (Constants.largeItemWidth - 5))
            "0"
            (model.items
                |> getAt 2
                |> Maybe.withDefault Item.emptyItem
            )

        -- DOES
        , canvasView model.settings
            Bottom
            Constants.largeItemWidth
            (itemHeight + 5)
            "0"
            (String.fromInt (itemHeight - 5))
            (model.items
                |> getAt 3
                |> Maybe.withDefault Item.emptyItem
            )

        -- FEELS
        , canvasView model.settings
            Bottom
            Constants.largeItemWidth
            (itemHeight + 5)
            (String.fromInt (Constants.largeItemWidth - 5))
            (String.fromInt (itemHeight - 5))
            (model.items
                |> getAt 4
                |> Maybe.withDefault Item.emptyItem
            )

        -- IMAGES
        , canvasImageView model.settings
            Constants.itemWidth
            Constants.itemHeight
            (String.fromInt (Constants.largeItemWidth - 5 - 150))
            (String.fromInt (itemHeight - 5 - 150))
            (model.items
                |> getAt 0
                |> Maybe.withDefault Item.emptyItem
            )
        ]


canvasImageView : Settings -> Int -> Int -> String -> String -> Item -> Svg Msg
canvasImageView settings svgWidth svgHeight posX posY item =
    svg
        [ width <| String.fromInt svgWidth
        , height <| String.fromInt svgHeight
        , x posX
        , y posY
        ]
        [ foreignObject
            [ x "0"
            , y "0"
            , width <| String.fromInt svgWidth
            , height <| String.fromInt svgHeight
            , class ".select-none"
            , fill settings.backgroundColor
            ]
            [ img
                [ Attr.src item.text
                , Attr.style "background-color" settings.backgroundColor
                , Attr.style "object-fit" "cover"
                , Attr.style "margin" "auto"
                , Attr.style "width" <| String.fromInt (svgWidth - 15) ++ "px"
                , Attr.style "height" <| String.fromInt (svgHeight - 15) ++ "px"
                , Attr.style "border-radius" "50%"
                , Attr.style "border" <| "6px solid " ++ settings.color.line
                , Attr.style "alt" ""
                ]
                []
            ]
        ]


canvasView : Settings -> Direction -> Int -> Int -> String -> String -> Item -> Svg Msg
canvasView settings direction svgWidth svgHeight posX posY item =
    let
        lines =
            Item.unwrapChildren item.children
                |> List.map (\i -> i.text)

        titleY =
            case direction of
                Top ->
                    10

                Bottom ->
                    svgHeight - 30

        textY =
            case direction of
                Top ->
                    35

                Bottom ->
                    160
    in
    svg
        [ width (String.fromInt svgWidth)
        , height (String.fromInt svgHeight)
        , x posX
        , y posY
        , fill settings.backgroundColor
        ]
        [ g []
            [ rectView (String.fromInt svgWidth) (String.fromInt svgHeight) settings.color.line
            , titleView settings (svgWidth // 2) titleY item.text
            , textView settings (Constants.largeItemWidth - 13) svgHeight 15 textY lines
            ]
        ]


rectView : String -> String -> String -> Svg Msg
rectView w h color =
    rect
        [ width w
        , height h
        , stroke color
        , strokeWidth "10"
        ]
        []


titleView : Settings -> Int -> Int -> String -> Svg Msg
titleView settings posX posY title =
    text_
        [ x (String.fromInt <| posX - 14 * String.length title)
        , y (String.fromInt (posY + 14))
        , fontFamily settings.font
        , fill settings.color.label
        , fontSize "24"
        , fontWeight "bold"
        , class ".select-none"
        ]
        [ text title ]


textView : Settings -> Int -> Int -> Int -> Int -> List String -> Svg Msg
textView settings w h posX posY lines =
    let
        maxLine =
            List.sortBy String.length lines
                |> last
                |> Maybe.withDefault ""
    in
    g []
        [ foreignObject
            [ x (String.fromInt posX)
            , y (String.fromInt posY)
            , width (String.fromInt w)
            , height (String.fromInt h)
            , color settings.color.label
            , fontSize <| Utils.calcFontSize w maxLine
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
        ]
