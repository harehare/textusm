module Views.Diagram.GanttChart exposing (view)

import Constants
import Data.FontSize as FontSize
import Data.Item as Item exposing (Item)
import Data.Position exposing (Position)
import Data.Size exposing (Size)
import Html
import Html.Attributes as Attr
import List.Extra as ListEx
import Models.Diagram as Diagram exposing (Model, Msg(..), Settings)
import Svg exposing (Svg)
import Svg.Attributes as SvgAttr
import Svg.Keyed as Keyed
import Time exposing (Posix)
import Time.Extra as TimeEx exposing (Interval(..))
import Tuple exposing (first, second)
import Utils.Date as DateUtils
import Views.Diagram.Views as Views


sectionMargin : Int
sectionMargin =
    Constants.leftMargin + 20


view : Model -> Svg Msg
view model =
    let
        rootItem =
            Item.head model.items |> Maybe.withDefault Item.new

        items =
            Item.unwrapChildren <| Item.getChildren rootItem

        nodeCounts =
            0
                :: (items
                        |> Item.map
                            (\i ->
                                if Item.isEmpty (Item.unwrapChildren <| Item.getChildren i) then
                                    0

                                else
                                    Item.getChildrenCount i // 2
                            )
                        |> ListEx.scanl1 (+)
                   )

        svgHeight =
            (ListEx.last nodeCounts |> Maybe.withDefault 1) * Constants.ganttItemSize + Item.length items * 2
    in
    case DateUtils.extractDateValues <| Item.getText rootItem of
        Just ( from, to ) ->
            let
                interval =
                    TimeEx.diff Day Time.utc from to

                lineWidth =
                    Constants.itemMargin
                        + interval
                        * Constants.ganttItemSize
            in
            Svg.g
                []
                (weekView model.settings
                    ( from, to )
                    :: daysView model.settings
                        svgHeight
                        ( from, to )
                    :: (ListEx.zip nodeCounts (Item.unwrap items)
                            |> List.concatMap
                                (\( count, sectionItem ) ->
                                    let
                                        taskItems =
                                            Item.unwrapChildren <| Item.getChildren sectionItem

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
            Svg.g [] []


daysView : Settings -> Int -> ( Posix, Posix ) -> Svg Msg
daysView settings svgHeight ( from, to ) =
    let
        daysNum =
            TimeEx.diff Day Time.utc from to
    in
    Svg.g []
        (List.range 0 daysNum
            |> List.map
                (\i ->
                    let
                        posX =
                            i * Constants.ganttItemSize + sectionMargin - 1

                        currentDay =
                            TimeEx.add Day i Time.utc from

                        day =
                            Time.toDay Time.utc currentDay
                    in
                    Keyed.node "g"
                        []
                        [ ( "day_" ++ DateUtils.millisToString Time.utc currentDay
                          , Svg.g []
                                [ Svg.foreignObject
                                    [ SvgAttr.x <| String.fromInt <| posX + 8
                                    , SvgAttr.y <| String.fromInt <| Constants.ganttItemSize - 16
                                    , SvgAttr.width <| String.fromInt <| sectionMargin
                                    , SvgAttr.height "30"
                                    , SvgAttr.fontSize "11"
                                    , SvgAttr.fontWeight "bold"
                                    , SvgAttr.fontFamily <| Diagram.fontStyle settings
                                    , SvgAttr.class "select-none"
                                    ]
                                    [ Html.div
                                        [ Attr.style "font-family" (Diagram.fontStyle settings)
                                        , Attr.style "word-wrap" "break-word"
                                        , Attr.style "color" settings.color.label
                                        ]
                                        [ Html.text <| String.fromInt day ]
                                    ]
                                , Svg.line
                                    [ SvgAttr.x1 <| String.fromInt posX
                                    , SvgAttr.y1 <| String.fromInt <| Constants.ganttItemSize
                                    , SvgAttr.x2 <| String.fromInt posX
                                    , SvgAttr.y2 <| String.fromInt <| Constants.ganttItemSize + svgHeight
                                    , SvgAttr.stroke settings.color.line
                                    , SvgAttr.strokeWidth "0.3"
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
            TimeEx.diff Day Time.utc from to // 7
    in
    Svg.g []
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
                          , Svg.foreignObject
                                [ SvgAttr.x posX
                                , SvgAttr.y <| String.fromInt <| Constants.ganttItemSize - 32
                                , SvgAttr.width <| String.fromInt <| sectionMargin
                                , SvgAttr.height "30"
                                , SvgAttr.class ".select-none"
                                ]
                                [ Html.div
                                    [ Attr.style "font-family" (Diagram.fontStyle settings)
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
            Item.getChildren item
                |> Item.unwrapChildren
                |> Item.map
                    (\childItem ->
                        Item.getChildren childItem |> Item.unwrapChildren |> Item.head |> Maybe.withDefault Item.new |> Item.getText
                    )
                |> List.maximum
    in
    Svg.g []
        [ Svg.line
            [ SvgAttr.x1 "0"
            , SvgAttr.y1 <| String.fromInt <| posY
            , SvgAttr.x2 <| String.fromInt <| posX + sectionWidth + sectionMargin + Constants.ganttItemSize
            , SvgAttr.y2 <| String.fromInt <| posY
            , SvgAttr.stroke settings.color.line
            , SvgAttr.strokeWidth "0.3"
            ]
            []
        , Svg.foreignObject
            [ SvgAttr.x <| String.fromInt <| posX
            , SvgAttr.y <| String.fromInt <| posY
            , SvgAttr.width <| String.fromInt <| sectionMargin - 2
            , SvgAttr.height <| String.fromInt <| sectionHeight
            , SvgAttr.class "select-none"
            ]
            [ Html.div
                [ Attr.style "font-family" (Diagram.fontStyle settings)
                , Attr.style "word-wrap" "break-word"
                , Attr.style "padding" "8px"
                , Attr.style "color" settings.color.label
                , Attr.style "font-size" "11px"
                , Attr.style "font-weight" "bold"
                ]
                [ Html.text <| Item.getText item ]
            ]
        , headerItemView settings
            ( settings.color.activity.backgroundColor
            , settings.color.text |> Maybe.withDefault settings.color.label
            )
            ( posX + sectionMargin - 1
            , posY
            )
            from
            (Item.getText item)
            (Item.withText (text |> Maybe.withDefault "") item)
        ]


sectionView : Settings -> Size -> Position -> Posix -> Item -> Svg Msg
sectionView settings ( sectionWidth, sectionHeight ) ( posX, posY ) from item =
    let
        childItem =
            Item.getChildren item |> Item.unwrapChildren |> Item.head |> Maybe.withDefault Item.new
    in
    Svg.g []
        [ Svg.line
            [ SvgAttr.x1 "0"
            , SvgAttr.y1 <| String.fromInt <| posY
            , SvgAttr.x2 <| String.fromInt <| posX + sectionWidth + sectionMargin - posX + Constants.ganttItemSize
            , SvgAttr.y2 <| String.fromInt <| posY
            , SvgAttr.stroke settings.color.line
            , SvgAttr.strokeWidth "0.3"
            ]
            []
        , Svg.foreignObject
            [ SvgAttr.x <| String.fromInt <| posX
            , SvgAttr.y <| String.fromInt <| posY
            , SvgAttr.width <| String.fromInt <| sectionMargin - posX - 2
            , SvgAttr.height <| String.fromInt <| sectionHeight
            , SvgAttr.class "select-none"
            ]
            [ Html.div
                [ Attr.style "font-family" (Diagram.fontStyle settings)
                , Attr.style "word-wrap" "break-word"
                , Attr.style "padding" "8px"
                , Attr.style "color" settings.color.label
                , Attr.style "font-size" "11px"
                , Attr.style "font-weight" "bold"
                ]
                [ Html.text <| Item.getText item ]
            ]
        , itemView settings
            ( settings.color.task.backgroundColor
            , settings.color.text |> Maybe.withDefault settings.color.label
            )
            ( sectionMargin - 1
            , posY
            )
            from
            (Item.getText item)
            childItem
        ]


itemView : Settings -> ( String, String ) -> Position -> Posix -> String -> Item -> Svg Msg
itemView settings colour ( posX, posY ) baseFrom text item =
    let
        values =
            DateUtils.extractDateValues <| Item.getText item
    in
    case values of
        Just ( from, to ) ->
            let
                interval =
                    TimeEx.diff Day Time.utc baseFrom from
            in
            taskView settings colour ( posX + interval * Constants.ganttItemSize, posY ) from to text

        Nothing ->
            Svg.g [] []


headerItemView : Settings -> ( String, String ) -> Position -> Posix -> String -> Item -> Svg Msg
headerItemView settings colour ( posX, posY ) baseFrom text item =
    let
        values =
            DateUtils.extractDateValues <| Item.getText item
    in
    case values of
        Just ( from, to ) ->
            let
                interval =
                    TimeEx.diff Day Time.utc baseFrom from
            in
            headerTaskView settings colour ( posX + interval * Constants.ganttItemSize, posY ) from to text

        Nothing ->
            Svg.g [] []


taskView : Settings -> ( String, String ) -> Position -> Posix -> Posix -> String -> Svg Msg
taskView settings ( backgroundColor, colour ) ( posX, posY ) from to text =
    let
        interval =
            TimeEx.diff Day Time.utc from to

        svgWidth =
            Constants.ganttItemSize * interval

        textWidth =
            String.length text * 20
    in
    Svg.svg
        [ SvgAttr.width <| String.fromInt (svgWidth + textWidth)
        , SvgAttr.height <| String.fromInt Constants.ganttItemSize
        , SvgAttr.x <| String.fromInt posX
        , SvgAttr.y <| String.fromInt posY
        ]
        [ Svg.rect
            [ SvgAttr.width <| String.fromInt <| svgWidth
            , SvgAttr.height <| String.fromInt <| Constants.ganttItemSize - 6
            , SvgAttr.x "0"
            , SvgAttr.y "5"
            , SvgAttr.fill backgroundColor
            , SvgAttr.rx "3"
            , SvgAttr.ry "3"
            ]
            []
        , Views.text settings ( svgWidth, 0 ) ( textWidth, Constants.ganttItemSize ) colour FontSize.default text
        ]


headerTaskView : Settings -> ( String, String ) -> Position -> Posix -> Posix -> String -> Svg Msg
headerTaskView settings ( backgroundColor, colour ) ( posX, posY ) from to text =
    let
        interval =
            TimeEx.diff Day Time.utc from to

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
    Svg.svg
        [ SvgAttr.width <| String.fromInt (svgWidth + textWidth)
        , SvgAttr.height <| String.fromInt Constants.ganttItemSize
        , SvgAttr.x <| String.fromInt posX
        , SvgAttr.y <| String.fromInt posY
        ]
        [ Svg.rect
            [ SvgAttr.width <| String.fromInt <| svgWidth
            , SvgAttr.height <| String.fromInt <| Constants.ganttItemSize // 2 - 8
            , SvgAttr.x "0"
            , SvgAttr.y <| String.fromInt <| Constants.ganttItemSize // 4
            , SvgAttr.fill backgroundColor
            ]
            []
        , Svg.polygon
            [ SvgAttr.points fromPolygon
            , SvgAttr.fill backgroundColor
            ]
            []
        , Svg.polygon
            [ SvgAttr.points toPolygon
            , SvgAttr.fill backgroundColor
            ]
            []
        , Views.text settings ( svgWidth, 0 ) ( textWidth, Constants.ganttItemSize ) colour FontSize.default text
        ]
