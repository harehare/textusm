module Views.Diagram.GanttChart exposing (view)

import Constants
import Html
import Html.Attributes as Attr
import List.Extra as ListEx
import Models.Diagram as Diagram exposing (Model, Msg, Settings)
import Models.Diagram.GanttChart as GanttChart exposing (GanttChart(..), Schedule(..), Section(..), Task(..))
import Models.FontSize as FontSize
import Models.Position exposing (Position)
import Models.Size exposing (Size)
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
    case model.data of
        Diagram.GanttChart (Just gantt) ->
            let
                (GanttChart (Schedule scheduleFrom scheduleTo interval) sections) =
                    gantt

                nodeCounts =
                    0
                        :: (sections
                                |> List.map
                                    (\(Section _ tasks) ->
                                        if List.isEmpty tasks then
                                            0

                                        else
                                            List.length tasks + 1
                                    )
                                |> ListEx.scanl1 (+)
                           )

                svgHeight =
                    (ListEx.last nodeCounts |> Maybe.withDefault 1) * Constants.ganttItemSize + List.length sections

                lineWidth =
                    Constants.itemMargin
                        + interval
                        * Constants.ganttItemSize
            in
            Svg.g
                []
                (weekView model.settings ( scheduleFrom, scheduleTo )
                    :: daysView model.settings svgHeight ( scheduleFrom, scheduleTo )
                    :: (ListEx.zip nodeCounts sections
                            |> List.concatMap
                                (\( count, section ) ->
                                    let
                                        posY =
                                            count * Constants.ganttItemSize

                                        (Section _ tasks) =
                                            section
                                    in
                                    headerSectionView
                                        model.settings
                                        ( lineWidth, Constants.ganttItemSize )
                                        ( 0
                                        , posY + Constants.ganttItemSize
                                        )
                                        scheduleFrom
                                        section
                                        :: (tasks
                                                |> List.indexedMap
                                                    (\i task ->
                                                        case task of
                                                            Nothing ->
                                                                []

                                                            Just t ->
                                                                [ sectionView
                                                                    model.settings
                                                                    ( lineWidth, Constants.ganttItemSize )
                                                                    ( 20
                                                                    , posY + ((i + 2) * Constants.ganttItemSize)
                                                                    )
                                                                    scheduleFrom
                                                                    t
                                                                ]
                                                    )
                                                |> List.concat
                                           )
                                )
                       )
                )

        _ ->
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


headerSectionView : Settings -> Size -> Position -> Posix -> Section -> Svg Msg
headerSectionView settings ( sectionWidth, sectionHeight ) ( posX, posY ) from section =
    let
        (Section title _) =
            section
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
                [ Html.text title ]
            ]
        , headerItemView settings
            ( settings.color.activity.backgroundColor
            , settings.color.text |> Maybe.withDefault settings.color.label
            )
            ( posX + sectionMargin - 1
            , posY
            )
            from
            title
          <|
            GanttChart.sectionSchedule section
        ]


sectionView : Settings -> Size -> Position -> Posix -> Task -> Svg Msg
sectionView settings ( sectionWidth, sectionHeight ) ( posX, posY ) from (Task title schedule) =
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
                [ Html.text title ]
            ]
        , itemView settings
            ( settings.color.task.backgroundColor
            , settings.color.text |> Maybe.withDefault settings.color.label
            )
            ( sectionMargin - 1
            , posY
            )
            from
            title
            schedule
        ]


itemView : Settings -> ( String, String ) -> Position -> Posix -> String -> Schedule -> Svg Msg
itemView settings colour ( posX, posY ) baseFrom text (Schedule from to _) =
    let
        interval =
            TimeEx.diff Day Time.utc baseFrom from
    in
    taskView settings colour ( posX + interval * Constants.ganttItemSize, posY ) from to text


headerItemView : Settings -> ( String, String ) -> Position -> Posix -> String -> Schedule -> Svg Msg
headerItemView settings colour ( posX, posY ) baseFrom text (Schedule from to _) =
    let
        interval =
            TimeEx.diff Day Time.utc baseFrom from
    in
    headerTaskView settings colour ( posX + interval * Constants.ganttItemSize, posY ) from to text


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
            , SvgAttr.y "3"
            , SvgAttr.fill backgroundColor
            , SvgAttr.rx "3"
            , SvgAttr.ry "3"
            ]
            []
        , Views.plainText settings ( svgWidth, -3 ) ( textWidth, Constants.ganttItemSize ) colour FontSize.default text
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
        , Views.plainText settings ( svgWidth, -3 ) ( textWidth, Constants.ganttItemSize ) colour FontSize.default text
        ]
