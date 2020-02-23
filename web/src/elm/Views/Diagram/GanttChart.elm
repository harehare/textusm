module Views.Diagram.GanttChart exposing (view)

import Constants
import Html exposing (div)
import Html.Attributes as Attr
import List.Extra exposing (last, scanl1, zip)
import Models.Diagram exposing (Model, Msg(..), Settings, fontStyle)
import Models.Item as Item exposing (Item)
import Svg exposing (Svg, foreignObject, g, line, polygon, rect, svg)
import Svg.Attributes exposing (class, color, fill, fontFamily, fontSize, fontWeight, height, points, rx, ry, stroke, strokeWidth, transform, width, x, x1, x2, y, y1, y2)
import Time exposing (Posix, toDay, utc)
import Time.Extra exposing (Interval(..), add, diff)
import Utils
import Views.Diagram.Views as Views exposing (Position, Size)


sectionMargin : Int
sectionMargin =
    Constants.leftMargin + 20


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
                                    Item.getChildrenCount i // 2 - 1
                            )
                        |> scanl1 (+)
                   )

        svgHeight =
            (last nodeCounts |> Maybe.withDefault 0) * Constants.ganttItemSize + List.length items * 2
    in
    case Utils.extractDateValues rootItem.text of
        Just ( from, to ) ->
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
                                        workItems =
                                            Item.unwrapChildren sectionItem.children

                                        posY =
                                            count * Constants.ganttItemSize
                                    in
                                    headerSectionView
                                        model.settings
                                        ( lineWidth, Constants.ganttItemSize )
                                        ( 0
                                        , posY + Constants.ganttItemSize
                                        )
                                        from
                                        sectionItem
                                        :: (workItems
                                                |> List.indexedMap
                                                    (\i workItem ->
                                                        let
                                                            newPosY =
                                                                posY + ((i + 2) * Constants.ganttItemSize)
                                                        in
                                                        [ sectionView
                                                            model.settings
                                                            ( lineWidth, Constants.ganttItemSize )
                                                            ( 20
                                                            , newPosY
                                                            )
                                                            from
                                                            workItem
                                                        ]
                                                    )
                                                |> List.concat
                                           )
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
                            i * Constants.ganttItemSize + sectionMargin - 1

                        day =
                            toDay utc <| add Day i utc from
                    in
                    g []
                        [ foreignObject
                            [ x <| String.fromInt <| posX + 8
                            , y <| String.fromInt <| Constants.ganttItemSize - 16
                            , width <| String.fromInt <| sectionMargin
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
                            String.fromInt <| i * 7 * Constants.ganttItemSize + sectionMargin - 1
                    in
                    g []
                        [ foreignObject
                            [ x posX
                            , y <| String.fromInt <| Constants.ganttItemSize - 32
                            , width <| String.fromInt <| sectionMargin
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


headerSectionView : Settings -> Size -> Position -> Posix -> Item -> Svg Msg
headerSectionView settings ( sectionWidth, sectionHeight ) ( posX, posY ) from item =
    let
        text =
            Item.unwrapChildren item.children
                |> List.map
                    (\childItem ->
                        Item.unwrapChildren childItem.children |> List.head |> Maybe.withDefault Item.emptyItem |> .text
                    )
                |> List.maximum
    in
    g []
        [ line
            [ x1 <| String.fromInt posX
            , y1 <| String.fromInt <| posY + 2
            , x2 <| String.fromInt <| posX + sectionWidth + sectionMargin
            , y2 <| String.fromInt <| posY + 2
            , stroke "#E2E2E2"
            , strokeWidth "0.5"
            ]
            []
        , foreignObject
            [ x <| String.fromInt <| posX
            , y <| String.fromInt <| posY + 3
            , width <| String.fromInt <| sectionMargin - 2
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
                [ Html.text item.text ]
            ]
        , headerItemView settings
            ( settings.color.activity.backgroundColor
            , settings.color.text |> Maybe.withDefault settings.color.label
            )
            ( posX + sectionMargin
            , posY
            )
            from
            item.text
            { item | text = text |> Maybe.withDefault "" }
        ]


sectionView : Settings -> Size -> Position -> Posix -> Item -> Svg Msg
sectionView settings ( sectionWidth, sectionHeight ) ( posX, posY ) from item =
    let
        childItem =
            Item.unwrapChildren item.children |> List.head |> Maybe.withDefault Item.emptyItem
    in
    g []
        [ line
            [ x1 <| String.fromInt posX
            , y1 <| String.fromInt <| posY + 2
            , x2 <| String.fromInt <| posX + sectionWidth + sectionMargin
            , y2 <| String.fromInt <| posY + 2
            , stroke "#E2E2E2"
            , strokeWidth "0.5"
            ]
            []
        , foreignObject
            [ x <| String.fromInt <| posX
            , y <| String.fromInt <| posY + 3
            , width <| String.fromInt <| sectionMargin - 2
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
                [ Html.text item.text ]
            ]
        , itemView settings
            ( settings.color.task.backgroundColor
            , settings.color.text |> Maybe.withDefault settings.color.label
            )
            ( sectionMargin
            , posY
            )
            from
            item.text
            childItem
        ]


itemView : Settings -> ( String, String ) -> Position -> Posix -> String -> Item -> Svg Msg
itemView settings colour ( posX, posY ) baseFrom text item =
    let
        values =
            Utils.extractDateValues item.text
    in
    case values of
        Just ( from, to ) ->
            let
                interval =
                    diff Day utc baseFrom from
            in
            taskView settings colour ( posX + interval * Constants.ganttItemSize, posY ) from to text

        Nothing ->
            g [] []


headerItemView : Settings -> ( String, String ) -> Position -> Posix -> String -> Item -> Svg Msg
headerItemView settings colour ( posX, posY ) baseFrom text item =
    let
        values =
            Utils.extractDateValues item.text
    in
    case values of
        Just ( from, to ) ->
            let
                interval =
                    diff Day utc baseFrom from
            in
            headerTaskView settings colour ( posX + interval * Constants.ganttItemSize, posY ) from to text

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
        [ rect
            [ width <| String.fromInt <| svgWidth
            , height <| String.fromInt <| Constants.ganttItemSize - 6
            , x "0"
            , y "5"
            , fill backgroundColor
            , rx "3"
            , ry "3"
            ]
            []
        , Views.textView settings ( svgWidth, 0 ) ( textWidth, Constants.ganttItemSize ) colour text
        ]


headerTaskView : Settings -> ( String, String ) -> Position -> Posix -> Posix -> String -> Svg Msg
headerTaskView settings ( backgroundColor, colour ) ( posX, posY ) from to text =
    let
        interval =
            diff Day utc from to

        svgWidth =
            Constants.ganttItemSize * interval

        textWidth =
            String.length text * 20

        startFromY =
            String.fromInt <| Constants.ganttItemSize // 4 + 1

        startToY =
            String.fromInt <| Constants.ganttItemSize // 4 + 16
    in
    svg
        [ width <| String.fromInt (svgWidth + textWidth)
        , height <| String.fromInt Constants.ganttItemSize
        , x <| String.fromInt posX
        , y <| String.fromInt posY
        ]
        [ rect
            [ width <| String.fromInt <| svgWidth
            , height <| String.fromInt <| Constants.ganttItemSize // 2 - 8
            , x "0"
            , y <| String.fromInt <| Constants.ganttItemSize // 4
            , fill backgroundColor
            ]
            []
        , polygon
            [ points <| "0," ++ startFromY ++ " 0," ++ startToY ++ " " ++ startToY ++ "," ++ startFromY
            , fill backgroundColor
            ]
            []
        , Views.textView settings ( svgWidth, 0 ) ( textWidth, Constants.ganttItemSize ) colour text
        ]
