module Views.Diagram.GanttChart exposing (view)

import Constants
import Data.Item as Item exposing (Item)
import Data.Position exposing (Position)
import Data.Size exposing (Size)
import Html exposing (div)
import Html.Attributes as Attr
import List.Extra exposing (last, scanl1, zip)
import Models.Diagram exposing (Model, Msg(..), Settings, fontStyle)
import Svg exposing (Svg, foreignObject, g, line, polygon, rect, svg)
import Svg.Attributes exposing (class, fill, fontFamily, fontSize, fontWeight, height, points, rx, ry, stroke, strokeWidth, transform, width, x, x1, x2, y, y1, y2)
import Svg.Keyed as Keyed
import Time exposing (Posix, toDay, utc)
import Time.Extra exposing (Interval(..), add, diff)
import Tuple exposing (first, second)
import Utils
import Views.Diagram.Views as Views


sectionMargin : Int
sectionMargin =
    Constants.leftMargin + 20


view : Model -> Svg Msg
view model =
    let
        rootItem =
            Item.head model.items |> Maybe.withDefault Item.emptyItem

        items =
            Item.unwrapChildren rootItem.children

        nodeCounts =
            0
                :: (items
                        |> Item.map
                            (\i ->
                                if Item.isEmpty (Item.unwrapChildren i.children) then
                                    0

                                else
                                    Item.getChildrenCount i // 2
                            )
                        |> scanl1 (+)
                   )

        svgHeight =
            (last nodeCounts |> Maybe.withDefault 1) * Constants.ganttItemSize + Item.length items * 2
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
                        ++ String.fromFloat
                            (if isInfinite <| model.x then
                                0

                             else
                                model.x
                            )
                        ++ ","
                        ++ String.fromFloat
                            (if isInfinite <| model.y then
                                0

                             else
                                model.y
                            )
                        ++ ")"
                    )
                ]
                (weekView model.settings
                    ( from, to )
                    :: daysView model.settings
                        svgHeight
                        ( from, to )
                    :: (zip nodeCounts (Item.unwrap items)
                            |> List.concatMap
                                (\( count, sectionItem ) ->
                                    let
                                        taskItems =
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
                                        :: (taskItems
                                                |> Item.indexedMap
                                                    (\i taskItem ->
                                                        [ sectionView
                                                            model.settings
                                                            ( lineWidth, Constants.ganttItemSize )
                                                            ( 20
                                                            , posY + ((i + 2) * Constants.ganttItemSize)
                                                            )
                                                            from
                                                            taskItem
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

                        currentDay =
                            add Day i utc from

                        day =
                            toDay utc currentDay
                    in
                    Keyed.node "g"
                        []
                        [ ( "day_" ++ Utils.millisToString utc currentDay
                          , g []
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
                                    , y1 <| String.fromInt <| Constants.ganttItemSize
                                    , x2 <| String.fromInt posX
                                    , y2 <| String.fromInt <| Constants.ganttItemSize + svgHeight
                                    , stroke settings.color.line
                                    , strokeWidth "0.3"
                                    ]
                                    []
                                ]
                          )
                        ]
                )
        )


weekView : Settings -> ( Posix, Posix ) -> Svg Msg
weekView settings ( from, to ) =
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
                    Keyed.node "g"
                        []
                        [ ( "week_" ++ String.fromInt i
                          , foreignObject
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
                          )
                        ]
                )
        )


headerSectionView : Settings -> Size -> Position -> Posix -> Item -> Svg Msg
headerSectionView settings ( sectionWidth, sectionHeight ) ( posX, posY ) from item =
    let
        text =
            Item.unwrapChildren item.children
                |> Item.map
                    (\childItem ->
                        Item.unwrapChildren childItem.children |> Item.head |> Maybe.withDefault Item.emptyItem |> .text
                    )
                |> List.maximum
    in
    g []
        [ line
            [ x1 "0"
            , y1 <| String.fromInt <| posY
            , x2 <| String.fromInt <| posX + sectionWidth + sectionMargin + Constants.ganttItemSize
            , y2 <| String.fromInt <| posY
            , stroke settings.color.line
            , strokeWidth "0.3"
            ]
            []
        , foreignObject
            [ x <| String.fromInt <| posX
            , y <| String.fromInt <| posY
            , width <| String.fromInt <| sectionMargin - 2
            , height <| String.fromInt <| sectionHeight
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
            ( posX + sectionMargin - 1
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
            Item.unwrapChildren item.children |> Item.head |> Maybe.withDefault Item.emptyItem
    in
    g []
        [ line
            [ x1 "0"
            , y1 <| String.fromInt <| posY
            , x2 <| String.fromInt <| posX + sectionWidth + sectionMargin - posX + Constants.ganttItemSize
            , y2 <| String.fromInt <| posY
            , stroke settings.color.line
            , strokeWidth "0.3"
            ]
            []
        , foreignObject
            [ x <| String.fromInt <| posX
            , y <| String.fromInt <| posY
            , width <| String.fromInt <| sectionMargin - posX - 2
            , height <| String.fromInt <| sectionHeight
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
            ( sectionMargin - 1
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

        triPosY =
            Constants.ganttItemSize // 4

        startFromY =
            triPosY + 1

        startTo =
            triPosY + 12

        polygonToString pol =
            pol
                |> List.map (\i -> String.fromInt (first i) ++ "," ++ String.fromInt (second i))
                |> String.join " "

        fromPolygon =
            [ ( 0, startFromY )
            , ( 0, startTo )
            , ( startTo, startFromY )
            ]
                |> polygonToString

        toPolygon =
            [ ( svgWidth - 20, startFromY )
            , ( svgWidth, startFromY )
            , ( svgWidth, startTo )
            ]
                |> polygonToString
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
            [ points fromPolygon
            , fill backgroundColor
            ]
            []
        , polygon
            [ points toPolygon
            , fill backgroundColor
            ]
            []
        , Views.textView settings ( svgWidth, 0 ) ( textWidth, Constants.ganttItemSize ) colour text
        ]
