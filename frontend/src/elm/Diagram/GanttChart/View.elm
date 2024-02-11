module Diagram.GanttChart.View exposing (docs, view)

import Constants
import Diagram.GanttChart.Types as GanttChart exposing (GanttChart(..), Schedule(..), Section(..), Task(..))
import Diagram.Types.Data as DiagramData
import Diagram.Types.Settings as DiagramSettings
import Diagram.Types.Type as DiagramType
import Diagram.View.Views as Views
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html.Styled as Html
import Html.Styled.Attributes as Attr
import List.Extra as ListEx
import Models.Color as Color exposing (Color)
import Models.FontSize as FontSize
import Models.Item as Item
import Models.Position exposing (Position)
import Models.Size exposing (Size)
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Attributes as SvgAttr
import Svg.Styled.Keyed as Keyed
import Time exposing (Posix)
import Time.Extra as TimeEx exposing (Interval(..))
import Tuple
import Utils.Date as DateUtils


view :
    { data : DiagramData.Data
    , settings : DiagramSettings.Settings
    }
    -> Svg msg
view { data, settings } =
    case data of
        DiagramData.GanttChart (Just gantt) ->
            let
                (GanttChart (Schedule scheduleFrom scheduleTo interval) sections) =
                    gantt

                lineWidth : Int
                lineWidth =
                    Constants.itemMargin
                        + interval
                        * Constants.ganttItemSize

                nodeCounts : List Int
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

                svgHeight : Int
                svgHeight =
                    (ListEx.last nodeCounts |> Maybe.withDefault 1) * Constants.ganttItemSize + List.length sections
            in
            Svg.g
                []
                (weekView settings ( scheduleFrom, scheduleTo )
                    :: daysView settings svgHeight ( scheduleFrom, scheduleTo )
                    :: (ListEx.zip nodeCounts sections
                            |> List.concatMap
                                (\( count, section ) ->
                                    let
                                        posY : Int
                                        posY =
                                            count * Constants.ganttItemSize

                                        (Section _ tasks) =
                                            section
                                    in
                                    headerSectionView
                                        settings
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
                                                            Just t ->
                                                                [ sectionView
                                                                    settings
                                                                    ( lineWidth, Constants.ganttItemSize )
                                                                    ( 20
                                                                    , posY + ((i + 2) * Constants.ganttItemSize)
                                                                    )
                                                                    scheduleFrom
                                                                    t
                                                                ]

                                                            Nothing ->
                                                                []
                                                    )
                                                |> List.concat
                                           )
                                )
                       )
                )

        _ ->
            Svg.g [] []


daysView : DiagramSettings.Settings -> Int -> ( Posix, Posix ) -> Svg msg
daysView settings svgHeight ( from, to ) =
    let
        daysNum : Int
        daysNum =
            TimeEx.diff Day Time.utc from to
    in
    Svg.g []
        (List.range 0 daysNum
            |> List.map
                (\i ->
                    let
                        currentDay : Posix
                        currentDay =
                            TimeEx.add Day i Time.utc from

                        day : Int
                        day =
                            Time.toDay Time.utc currentDay

                        posX : Int
                        posX =
                            i * Constants.ganttItemSize + sectionMargin - 1
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
                                    , SvgAttr.fontFamily <| DiagramSettings.fontStyle settings
                                    ]
                                    [ Html.div
                                        [ Attr.style "font-family" (DiagramSettings.fontStyle settings)
                                        , Attr.style "word-wrap" "break-word"
                                        , Attr.style "color" <| Color.toString settings.color.label
                                        ]
                                        [ Html.text <| String.fromInt day ]
                                    ]
                                , Svg.line
                                    [ SvgAttr.x1 <| String.fromInt posX
                                    , SvgAttr.y1 <| String.fromInt <| Constants.ganttItemSize
                                    , SvgAttr.x2 <| String.fromInt posX
                                    , SvgAttr.y2 <| String.fromInt <| Constants.ganttItemSize + svgHeight
                                    , SvgAttr.stroke <| Color.toString settings.color.line
                                    , SvgAttr.strokeWidth "0.3"
                                    ]
                                    []
                                ]
                          )
                        ]
                )
        )


headerItemView : DiagramSettings.Settings -> ( Color, Color ) -> Position -> Posix -> String -> Schedule -> Svg msg
headerItemView settings colour ( posX, posY ) baseFrom text (Schedule from to _) =
    let
        interval : Int
        interval =
            TimeEx.diff Day Time.utc baseFrom from
    in
    headerTaskView settings colour ( posX + interval * Constants.ganttItemSize, posY ) from to text


headerSectionView : DiagramSettings.Settings -> Size -> Position -> Posix -> Section -> Svg msg
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
            , SvgAttr.stroke <| Color.toString settings.color.line
            , SvgAttr.strokeWidth "0.3"
            ]
            []
        , Svg.foreignObject
            [ SvgAttr.x <| String.fromInt <| posX
            , SvgAttr.y <| String.fromInt <| posY
            , SvgAttr.width <| String.fromInt <| sectionMargin - 2
            , SvgAttr.height <| String.fromInt <| sectionHeight
            ]
            [ Html.div
                [ Attr.style "font-family" (DiagramSettings.fontStyle settings)
                , Attr.style "word-wrap" "break-word"
                , Attr.style "padding" "8px"
                , Attr.style "color" <| Color.toString settings.color.label
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


headerTaskView : DiagramSettings.Settings -> ( Color, Color ) -> Position -> Posix -> Posix -> String -> Svg msg
headerTaskView settings ( backgroundColor, colour ) ( posX, posY ) from to text =
    let
        fromPolygon : String
        fromPolygon =
            [ ( 0, startFromY )
            , ( 0, startTo )
            , ( startTo, startFromY )
            ]
                |> polygonToString

        interval : Int
        interval =
            TimeEx.diff Day Time.utc from to

        polygonToString : List ( Int, Int ) -> String
        polygonToString pol =
            pol
                |> List.map (\i -> String.fromInt (Tuple.first i) ++ "," ++ String.fromInt (Tuple.second i))
                |> String.join " "

        startFromY : Int
        startFromY =
            triPosY + 1

        startTo : Int
        startTo =
            triPosY + 12

        svgWidth : Int
        svgWidth =
            Constants.ganttItemSize * interval

        textWidth : Int
        textWidth =
            String.length text * 20

        toPolygon : String
        toPolygon =
            [ ( svgWidth - 20, startFromY )
            , ( svgWidth, startFromY )
            , ( svgWidth, startTo )
            ]
                |> polygonToString

        triPosY : Int
        triPosY =
            Constants.ganttItemSize // 4
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
            , SvgAttr.fill <| Color.toString backgroundColor
            ]
            []
        , Svg.polygon
            [ SvgAttr.points fromPolygon
            , SvgAttr.fill <| Color.toString backgroundColor
            ]
            []
        , Svg.polygon
            [ SvgAttr.points toPolygon
            , SvgAttr.fill <| Color.toString backgroundColor
            ]
            []
        , Views.plainText
            { settings = settings
            , position = ( svgWidth, -3 )
            , size = ( textWidth, Constants.ganttItemSize )
            , foreColor = colour
            , fontSize = FontSize.default
            , text = text
            , isHighlight = False
            }
        ]


itemView : DiagramSettings.Settings -> ( Color, Color ) -> Position -> Posix -> String -> Schedule -> Svg msg
itemView settings colour ( posX, posY ) baseFrom text (Schedule from to _) =
    let
        interval : Int
        interval =
            TimeEx.diff Day Time.utc baseFrom from
    in
    taskView settings colour ( posX + interval * Constants.ganttItemSize, posY ) from to text


sectionMargin : Int
sectionMargin =
    Constants.leftMargin + 20


sectionView : DiagramSettings.Settings -> Size -> Position -> Posix -> Task -> Svg msg
sectionView settings ( sectionWidth, sectionHeight ) ( posX, posY ) from (Task title schedule) =
    Svg.g []
        [ Svg.line
            [ SvgAttr.x1 "0"
            , SvgAttr.y1 <| String.fromInt <| posY
            , SvgAttr.x2 <| String.fromInt <| posX + sectionWidth + sectionMargin - posX + Constants.ganttItemSize
            , SvgAttr.y2 <| String.fromInt <| posY
            , SvgAttr.stroke <| Color.toString settings.color.line
            , SvgAttr.strokeWidth "0.3"
            ]
            []
        , Svg.foreignObject
            [ SvgAttr.x <| String.fromInt <| posX
            , SvgAttr.y <| String.fromInt <| posY
            , SvgAttr.width <| String.fromInt <| sectionMargin - posX - 2
            , SvgAttr.height <| String.fromInt <| sectionHeight
            ]
            [ Html.div
                [ Attr.style "font-family" (DiagramSettings.fontStyle settings)
                , Attr.style "word-wrap" "break-word"
                , Attr.style "padding" "8px"
                , Attr.style "color" <| Color.toString settings.color.label
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


taskView : DiagramSettings.Settings -> ( Color, Color ) -> Position -> Posix -> Posix -> String -> Svg msg
taskView settings ( backgroundColor, colour ) ( posX, posY ) from to text =
    let
        interval : Int
        interval =
            TimeEx.diff Day Time.utc from to

        svgWidth : Int
        svgWidth =
            Constants.ganttItemSize * interval

        textWidth : Int
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
            , SvgAttr.fill <| Color.toString backgroundColor
            , SvgAttr.rx "3"
            , SvgAttr.ry "3"
            ]
            []
        , Views.plainText
            { settings = settings
            , position = ( svgWidth, -3 )
            , size = ( textWidth, Constants.ganttItemSize )
            , foreColor = colour
            , fontSize = FontSize.default
            , text = text
            , isHighlight = False
            }
        ]


weekView : DiagramSettings.Settings -> ( Posix, Posix ) -> Svg msg
weekView settings ( from, to ) =
    let
        weekNum : Int
        weekNum =
            TimeEx.diff Day Time.utc from to // 7
    in
    Svg.g []
        (List.range 0 weekNum
            |> List.map
                (\i ->
                    let
                        posX : String
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
                                ]
                                [ Html.div
                                    [ Attr.style "font-family" (DiagramSettings.fontStyle settings)
                                    , Attr.style "word-wrap" "break-word"
                                    , Attr.style "color" <| Color.toString settings.color.label
                                    , Attr.style "font-size" "11px"
                                    , Attr.style "font-weight" "bold"
                                    ]
                                    [ Html.text <| "Week " ++ (String.fromInt <| i + 1) ]
                                ]
                          )
                        ]
                )
        )


docs : Chapter x
docs =
    Chapter.chapter "GanttChart"
        |> Chapter.renderComponent
            (Svg.svg
                [ SvgAttr.width "100%"
                , SvgAttr.height "100%"
                , SvgAttr.viewBox "0 0 2048 2048"
                ]
                [ view
                    { data =
                        DiagramData.GanttChart <|
                            GanttChart.from
                                (DiagramType.defaultText DiagramType.GanttChart |> Item.fromString |> Tuple.second)
                    , settings = DiagramSettings.default
                    }
                ]
                |> Svg.toUnstyled
            )
