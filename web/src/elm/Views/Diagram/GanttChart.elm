module Views.Diagram.GanttChart exposing (view)

import Constants
import Html exposing (div)
import Html.Attributes as Attr
import List.Extra exposing (last, scanl1, zip)
import Models.Diagram exposing (Model, Msg(..), Settings)
import Models.Item as Item exposing (Item)
import Svg exposing (Svg, foreignObject, g, line, rect, svg)
import Svg.Attributes exposing (class, color, fill, fontFamily, fontSize, fontWeight, height, stroke, strokeWidth, transform, width, x, x1, x2, y, y1, y2)
import Time exposing (Posix, utc)
import Time.Extra exposing (Interval(..), diff)
import Utils
import Views.Diagram.Views as Views


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
                                    Item.getChildrenCount i - 1
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
                    :: (zip nodeCounts items
                            |> List.concatMap
                                (\( count, sectionItem ) ->
                                    let
                                        sectionItems =
                                            Item.unwrapChildren sectionItem.children

                                        posY =
                                            count * Constants.ganttItemSize + Constants.ganttItemSize
                                    in
                                    sectionView
                                        model.settings
                                        lineWidth
                                        (List.length sectionItems * Constants.ganttItemSize)
                                        ( 0
                                        , posY
                                        )
                                        sectionItem.text
                                        :: List.indexedMap
                                            (\i item ->
                                                itemView model.settings
                                                    i
                                                    ( Constants.leftMargin
                                                    , posY + i * Constants.ganttItemSize
                                                    )
                                                    from
                                                    item
                                            )
                                            sectionItems
                                )
                       )
                )

        Nothing ->
            g [] []


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
                            , y <| String.fromInt <| Constants.ganttItemSize - 16
                            , width <| String.fromInt <| Constants.leftMargin
                            , height "30"
                            , color settings.color.label
                            , fontSize "11"
                            , fontWeight "bold"
                            , fontFamily settings.font
                            , class ".select-none"
                            ]
                            [ div
                                [ Attr.style "font-family" ("'" ++ settings.font ++ "', sans-serif")
                                , Attr.style "word-wrap" "break-word"
                                ]
                                [ Html.text <| "Week " ++ (String.fromInt <| i + 1) ]
                            ]
                        , line
                            [ x1 posX
                            , y1 <| String.fromInt <| Constants.ganttItemSize + 2
                            , x2 posX
                            , y2 <| String.fromInt <| Constants.ganttItemSize + svgHeight - 2
                            , stroke settings.color.line
                            , strokeWidth "0.5"
                            ]
                            []
                        ]
                )
        )


sectionView : Settings -> Int -> Int -> ( Int, Int ) -> String -> Svg Msg
sectionView settings sectionWidth sectionHeight ( posX, posY ) text =
    g []
        [ line
            [ x1 <| String.fromInt posX
            , y1 <| String.fromInt <| posY + 2
            , x2 <| String.fromInt <| posX + sectionWidth + Constants.leftMargin
            , y2 <| String.fromInt <| posY + 2
            , stroke settings.color.line
            , strokeWidth "0.5"
            ]
            []
        , foreignObject
            [ x <| String.fromInt <| posX
            , y <| String.fromInt <| posY + 3
            , width <| String.fromInt <| Constants.leftMargin - 2
            , height <| String.fromInt <| sectionHeight - 2
            , color settings.color.activity.color
            , Attr.style "background-color" settings.color.activity.backgroundColor
            , fontSize "11"
            , fontWeight "bold"
            , fontFamily settings.font
            , class ".select-none"
            ]
            [ div
                [ Attr.style "font-family" ("'" ++ settings.font ++ "', sans-serif")
                , Attr.style "word-wrap" "break-word"
                , Attr.style "padding" "8px"
                ]
                [ Html.text text ]
            ]
        ]


itemView : Settings -> Int -> ( Int, Int ) -> Posix -> Item -> Svg Msg
itemView settings index ( posX, posY ) baseFrom item =
    let
        values =
            Utils.extractDateValues item.text

        isOdd =
            if index == 0 then
                False

            else
                modBy 2 index == 1
    in
    case values of
        Just ( ( from, to ), text ) ->
            let
                interval =
                    diff Day utc baseFrom from

                colour =
                    if isOdd then
                        ( settings.color.story.backgroundColor, settings.color.text |> Maybe.withDefault settings.color.label )

                    else
                        ( settings.color.task.backgroundColor, settings.color.text |> Maybe.withDefault settings.color.label )
            in
            taskView settings colour ( posX + interval * Constants.ganttItemSize, posY ) from to text

        Nothing ->
            g [] []


taskView : Settings -> ( String, String ) -> ( Int, Int ) -> Posix -> Posix -> String -> Svg Msg
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
            , Constants.ganttItemSize
            )
            backgroundColor
        , Views.textView settings ( svgWidth, 0 ) ( textWidth, Constants.ganttItemSize ) colour text
        ]


rectView : ( Int, Int ) -> String -> Svg Msg
rectView ( svgWidth, svgHeight ) color =
    rect
        [ width <| String.fromInt <| svgWidth
        , height <| String.fromInt <| svgHeight
        , x "0"
        , y "3"
        , fill color
        ]
        []
