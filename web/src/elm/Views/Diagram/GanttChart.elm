module Views.Diagram.GanttChart exposing (view)

import Constants
import Html exposing (div)
import Html.Attributes as Attr
import List.Extra exposing (last, scanl1, zip)
import Models.Diagram exposing (Model, Msg(..), Settings, fontStyle)
import Models.Item as Item exposing (Item)
import Svg exposing (Svg, foreignObject, g, line, rect, svg)
import Svg.Attributes exposing (class, color, fill, fontFamily, fontSize, fontWeight, height, rx, ry, stroke, strokeWidth, transform, width, x, x1, x2, y, y1, y2)
import Time exposing (Posix, toDay, utc)
import Time.Extra exposing (Interval(..), add, diff)
import Utils
import Views.Diagram.Views as Views exposing (Position, Size)


view : Model -> Svg Msg
view model =
    let
        rootItem =
            List.head model.items |> Maybe.withDefault Item.emptyItem

        items =
            Item.unwrapChildren rootItem.children

        nodeCounts =
            0
                :: (items
                        |> List.map
                            (\i ->
                                if List.isEmpty (Item.unwrapChildren i.children) then
                                    0

                                else
                                    1
                            )
                        |> scanl1 (+)
                   )

        svgHeight =
            (last nodeCounts |> Maybe.withDefault 0) * Constants.ganttItemSize + List.length items * 2
    in
    case Utils.extractDateValues rootItem.text of
        Just ( ( from, to ), _ ) ->
            let
                interval =
                    diff Day utc from to

                lineWidth =
                    Constants.itemMargin
                        + interval
                        * Constants.ganttItemSize
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
                ]
                (weekView model.settings
                    svgHeight
                    ( from, to )
                    :: daysView model.settings
                        svgHeight
                        ( from, to )
                    :: (zip nodeCounts items
                            |> List.concatMap
                                (\( count, sectionItem ) ->
                                    let
                                        item =
                                            Item.unwrapChildren sectionItem.children |> List.head |> Maybe.withDefault Item.emptyItem

                                        posY =
                                            count * Constants.ganttItemSize
                                    in
                                    [ sectionView
                                        model.settings
                                        ( lineWidth, Constants.ganttItemSize )
                                        ( 0
                                        , posY + Constants.ganttItemSize
                                        )
                                        sectionItem.text
                                    , itemView model.settings
                                        ( model.settings.color.activity.backgroundColor, model.settings.color.text |> Maybe.withDefault model.settings.color.label )
                                        ( Constants.leftMargin
                                        , posY + Constants.ganttItemSize
                                        )
                                        from
                                        item
                                    ]
                                )
                       )
                )

        Nothing ->
            g [] []


daysView : Settings -> Int -> ( Posix, Posix ) -> Svg Msg
daysView settings svgHeight ( from, to ) =
    let
        daysNum =
            diff Day utc from to
    in
    g []
        (List.range 0 daysNum
            |> List.map
                (\i ->
                    let
                        posX =
                            i * Constants.ganttItemSize + Constants.leftMargin - 1

                        day =
                            toDay utc <| add Day i utc from
                    in
                    g []
                        [ foreignObject
                            [ x <| String.fromInt <| posX + 8
                            , y <| String.fromInt <| Constants.ganttItemSize - 16
                            , width <| String.fromInt <| Constants.leftMargin
                            , height "30"
                            , fontSize "11"
                            , fontWeight "bold"
                            , fontFamily <| fontStyle settings
                            , class ".select-none"
                            ]
                            [ div
                                [ Attr.style "font-family" (fontStyle settings)
                                , Attr.style "word-wrap" "break-word"
                                , Attr.style "color" settings.color.label
                                ]
                                [ Html.text <| String.fromInt day ]
                            ]
                        , line
                            [ x1 <| String.fromInt posX
                            , y1 <| String.fromInt <| Constants.ganttItemSize + 2
                            , x2 <| String.fromInt posX
                            , y2 <| String.fromInt <| Constants.ganttItemSize + svgHeight - 2
                            , stroke "#D7D8DF"
                            , strokeWidth "0.5"
                            ]
                            []
                        ]
                )
        )


weekView : Settings -> Int -> ( Posix, Posix ) -> Svg Msg
weekView settings svgHeight ( from, to ) =
    let
        weekNum =
            diff Day utc from to // 7
    in
    g []
        (List.range 0 weekNum
            |> List.map
                (\i ->
                    let
                        posX =
                            String.fromInt <| i * 7 * Constants.ganttItemSize + Constants.leftMargin - 1
                    in
                    g []
                        [ foreignObject
                            [ x posX
                            , y <| String.fromInt <| Constants.ganttItemSize - 32
                            , width <| String.fromInt <| Constants.leftMargin
                            , height "30"
                            , class ".select-none"
                            ]
                            [ div
                                [ Attr.style "font-family" (fontStyle settings)
                                , Attr.style "word-wrap" "break-word"
                                , Attr.style "color" settings.color.label
                                , Attr.style "font-size" "11px"
                                , Attr.style "font-weight" "bold"
                                ]
                                [ Html.text <| "Week " ++ (String.fromInt <| i + 1) ]
                            ]
                        , line
                            [ x1 posX
                            , y1 <| String.fromInt <| Constants.ganttItemSize + 2
                            , x2 posX
                            , y2 <| String.fromInt <| Constants.ganttItemSize + svgHeight - 2
                            , stroke "#D7D8DF"
                            , strokeWidth "0.5"
                            ]
                            []
                        ]
                )
        )


sectionView : Settings -> Size -> Position -> String -> Svg Msg
sectionView settings ( sectionWidth, sectionHeight ) ( posX, posY ) text =
    g []
        [ line
            [ x1 <| String.fromInt posX
            , y1 <| String.fromInt <| posY + 2
            , x2 <| String.fromInt <| posX + sectionWidth + Constants.leftMargin
            , y2 <| String.fromInt <| posY + 2
            , stroke "#E2E2E2"
            , strokeWidth "0.5"
            ]
            []
        , foreignObject
            [ x <| String.fromInt <| posX
            , y <| String.fromInt <| posY + 3
            , width <| String.fromInt <| Constants.leftMargin - 2
            , height <| String.fromInt <| sectionHeight - 2
            , color "#4A4A4A"
            , Attr.style "background-color" "#FFFFFF"
            , class ".select-none"
            ]
            [ div
                [ Attr.style "font-family" (fontStyle settings)
                , Attr.style "word-wrap" "break-word"
                , Attr.style "padding" "8px"
                , Attr.style "color" settings.color.label
                , Attr.style "font-size" "11px"
                , Attr.style "font-weight" "bold"
                ]
                [ Html.text text ]
            ]
        ]


itemView : Settings -> ( String, String ) -> Position -> Posix -> Item -> Svg Msg
itemView settings colour ( posX, posY ) baseFrom item =
    let
        values =
            Utils.extractDateValues item.text
    in
    case values of
        Just ( ( from, to ), text ) ->
            let
                interval =
                    diff Day utc baseFrom from
            in
            taskView settings colour ( posX + interval * Constants.ganttItemSize, posY ) from to text

        Nothing ->
            g [] []


taskView : Settings -> ( String, String ) -> Position -> Posix -> Posix -> String -> Svg Msg
taskView settings ( backgroundColor, colour ) ( posX, posY ) from to text =
    let
        interval =
            diff Day utc from to

        svgWidth =
            Constants.ganttItemSize * interval

        textWidth =
            String.length text * 20
    in
    svg
        [ width <| String.fromInt (svgWidth + textWidth)
        , height <| String.fromInt Constants.ganttItemSize
        , x <| String.fromInt posX
        , y <| String.fromInt posY
        ]
        [ rectView
            ( svgWidth
            , Constants.ganttItemSize - 6
            )
            backgroundColor
        , Views.textView settings ( svgWidth, 0 ) ( textWidth, Constants.ganttItemSize ) colour text
        ]


rectView : Size -> String -> Svg Msg
rectView ( svgWidth, svgHeight ) color =
    rect
        [ width <| String.fromInt <| svgWidth
        , height <| String.fromInt <| svgHeight
        , x "0"
        , y "5"
        , fill color
        , rx "3"
        , ry "3"
        ]
        []
