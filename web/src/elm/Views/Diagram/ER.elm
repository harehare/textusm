module Views.Diagram.ER exposing (view)

import Constants
import Data.Position as Position exposing (Position, getX, getY)
import Data.Size as Size exposing (Size, getHeight, getWidth)
import Dict as Dict exposing (Dict)
import Events
import Html exposing (div)
import Html.Attributes as Attr
import Html.Lazy exposing (lazy, lazy3)
import List.Extra exposing (find, getAt)
import Maybe.Extra exposing (isJust, isNothing, or)
import Models.Diagram as Diagram exposing (Model, Msg(..), Settings, fontStyle)
import Models.Views.ER as ER exposing (Attribute(..), Column(..), ColumnType(..), Relationship(..), Table(..))
import State as State exposing (Step(..))
import String
import Svg exposing (Svg, foreignObject, g, rect, text, text_)
import Svg.Attributes exposing (class, fill, fontFamily, fontSize, fontWeight, height, stroke, strokeWidth, width, x, y)
import Utils
import Views.Diagram.Path as Path
import Views.Empty as Empty
import Views.Icon as Icon


type alias TableViewInfo =
    { table : Table
    , size : Size
    , position : Maybe Position
    , releationCount : Int
    , releations : Dict String String
    , offset : Position
    }


type alias TableViewDict =
    Dict String TableViewInfo


view : Model -> Svg Msg
view model =
    case model.data of
        Diagram.ErDiagram e ->
            let
                ( relationships, tables ) =
                    e

                baseDict =
                    tablesToDict tables
                        |> adjustTablePosition relationships

                tableDict =
                    case model.moveState of
                        Diagram.ItemMove target ->
                            case target of
                                Diagram.TableTarget table ->
                                    let
                                        (Table name columns position _) =
                                            table

                                        currentTable =
                                            Dict.get name baseDict
                                    in
                                    Dict.update name
                                        (\v ->
                                            currentTable
                                                |> Maybe.andThen (\t -> Just { t | table = table, offset = position |> Maybe.withDefault Position.zero })
                                        )
                                        baseDict

                                _ ->
                                    baseDict

                        _ ->
                            baseDict
            in
            g
                []
                (lazy3 relationshipView model.settings relationships tableDict
                    :: (Dict.toList tableDict
                            |> List.map
                                (\( _, t ) ->
                                    lazy tableView { settings = model.settings, svgSize = model.size, pos = getPosition t.position, tableSize = t.size, table = t.table }
                                )
                       )
                )

        _ ->
            Empty.view


adjustTablePosition : List Relationship -> TableViewDict -> TableViewDict
adjustTablePosition r t =
    let
        go { nextPosition, tablePositions, relationships } =
            if List.isEmpty relationships then
                Done tablePositions

            else
                case relationships of
                    x :: xs ->
                        case ER.relationshipToString x of
                            Just ( ( tableName1, relationString1 ), ( tableName2, relationString2 ) ) ->
                                let
                                    maybeTable1 =
                                        Dict.get tableName1 tablePositions

                                    maybeTable2 =
                                        Dict.get tableName2 tablePositions
                                in
                                case ( maybeTable1, maybeTable2 ) of
                                    ( Just t1, Just t2 ) ->
                                        let
                                            ( ( table1, name1, rel1 ), ( table2, name2, rel2 ) ) =
                                                if t1.releationCount >= t2.releationCount && isNothing t2.position then
                                                    ( ( t1, tableName1, relationString1 ), ( t2, tableName2, relationString2 ) )

                                                else
                                                    ( ( t2, tableName2, relationString2 ), ( t1, tableName1, relationString1 ) )

                                            ( next, childPosition ) =
                                                calcTablePosition
                                                    { tableSize1 = table1.size
                                                    , tableSize2 = table2.size
                                                    , pos = table1.position
                                                    , nextPosition = nextPosition
                                                    , relationCount = table1.releationCount + 1
                                                    }

                                            table1Updated =
                                                Dict.update
                                                    name1
                                                    (Maybe.map
                                                        (\v ->
                                                            { v
                                                                | releationCount = table1.releationCount + 1
                                                                , releations = Dict.insert name2 rel1 v.releations
                                                            }
                                                        )
                                                    )
                                                    tablePositions

                                            table2Updated =
                                                Dict.update
                                                    name2
                                                    (Maybe.map
                                                        (\v ->
                                                            { v
                                                                | position = Just childPosition
                                                                , releationCount = table1.releationCount + 1
                                                                , releations = Dict.insert name1 rel2 v.releations
                                                            }
                                                        )
                                                    )
                                                    table1Updated
                                        in
                                        Loop
                                            { tablePositions = table2Updated
                                            , relationships = xs
                                            , nextPosition = or next nextPosition
                                            }

                                    _ ->
                                        Loop
                                            { tablePositions = tablePositions
                                            , relationships = xs
                                            , nextPosition = nextPosition
                                            }

                            Nothing ->
                                Loop
                                    { tablePositions = tablePositions
                                    , relationships = xs
                                    , nextPosition = nextPosition
                                    }

                    _ ->
                        Loop
                            { tablePositions = tablePositions
                            , relationships = []
                            , nextPosition = nextPosition
                            }
    in
    State.tailRec go { nextPosition = Nothing, relationships = r, tablePositions = t }


calcTablePosition :
    { tableSize1 : Size
    , tableSize2 : Size
    , pos : Maybe Position
    , nextPosition : Maybe Position
    , relationCount : Int
    }
    -> ( Maybe Position, Position )
calcTablePosition { tableSize1, tableSize2, pos, nextPosition, relationCount } =
    let
        ( tableWidth1, tableHeight1 ) =
            tableSize1

        ( tableWidth2, tableHeight2 ) =
            tableSize2

        n =
            if relationCount // 8 > 0 then
                relationCount // 8

            else
                1

        w =
            max tableWidth1 Constants.tableMargin * n

        h =
            max tableHeight1 Constants.tableMargin * n

        ( next, ( posX, posY ) ) =
            case pos of
                Just ( x, y ) ->
                    ( Nothing, ( x, y ) )

                Nothing ->
                    case nextPosition of
                        Just ( nextX, nextY ) ->
                            ( Just ( nextX + tableWidth1 + w, nextY ), ( nextX, nextY ) )

                        Nothing ->
                            ( Just ( tableWidth1 + w, 0 ), ( 0, 0 ) )
    in
    case modBy 8 relationCount of
        1 ->
            ( next, ( posX, posY - h - tableHeight2 ) )

        2 ->
            ( next, ( posX + tableWidth1 + w, posY - h - tableHeight2 ) )

        3 ->
            ( next, ( posX + tableWidth1 + w, posY ) )

        4 ->
            ( next, ( posX + tableWidth1 + w, posY + h + tableHeight1 ) )

        5 ->
            ( next, ( posX, posY + h + tableHeight1 ) )

        6 ->
            ( next, ( posX - tableWidth2 - w, posY + tableHeight1 + h ) )

        7 ->
            ( next, ( posX - tableWidth1 - w, posY ) )

        8 ->
            ( next, ( posX - tableWidth1 - w, posY + tableHeight1 - h ) )

        _ ->
            ( next, ( posX, posY - h - tableHeight2 ) )


tablesToDict : List Table -> TableViewDict
tablesToDict tables =
    tables
        |> List.map
            (\table ->
                let
                    (Table name columns position _) =
                        table

                    offsetX =
                        Position.getX (position |> Maybe.withDefault Position.zero)

                    offsetY =
                        Position.getY (position |> Maybe.withDefault Position.zero)

                    width =
                        ER.tableWidth table

                    height =
                        Constants.tableRowHeight * (List.length columns + 1)
                in
                ( name
                , { table = table
                  , size = ( width, height )
                  , position = Nothing
                  , releationCount = 0
                  , releations = Dict.empty
                  , offset = ( offsetX, offsetY )
                  }
                )
            )
        |> Dict.fromList


tableView : { settings : Settings, svgSize : Size, pos : Position, tableSize : Size, table : Table } -> Svg Msg
tableView { settings, svgSize, pos, tableSize, table } =
    let
        (Table tableName columns position _) =
            table

        tableX =
            Position.getX pos + Position.getX (position |> Maybe.withDefault Position.zero)

        tableY =
            Position.getY pos + Position.getY (position |> Maybe.withDefault Position.zero)
    in
    g
        [ onDragStart table (Utils.isPhone (Size.getWidth svgSize)) ]
        (rect
            [ width <| String.fromInt <| Size.getWidth tableSize
            , height <| String.fromInt <| Size.getHeight tableSize
            , x (String.fromInt tableX)
            , y (String.fromInt tableY)
            , strokeWidth "1"
            , stroke settings.color.activity.backgroundColor
            ]
            []
            :: tableHeaderView settings tableName (Size.getWidth tableSize) ( tableX, tableY )
            :: List.indexedMap
                (\i column -> columnView settings (Size.getWidth tableSize) ( tableX, tableY + Constants.tableRowHeight * (i + 1) ) column)
                columns
        )


onDragStart : Table -> Bool -> Svg.Attribute Msg
onDragStart table isPhone =
    if isPhone then
        Events.onTouchStart
            (\event ->
                if List.length event.changedTouches > 1 then
                    let
                        p1 =
                            getAt 0 event.changedTouches
                                |> Maybe.map .pagePos
                                |> Maybe.withDefault ( 0, 0 )

                        p2 =
                            getAt 1 event.changedTouches
                                |> Maybe.map .pagePos
                                |> Maybe.withDefault ( 0, 0 )
                    in
                    StartPinch (Utils.calcDistance p1 p2)

                else
                    let
                        ( x, y ) =
                            Events.touchCoordinates event
                    in
                    Start (Diagram.ItemMove (Diagram.TableTarget table)) ( round x, round y )
            )

    else
        Events.onMouseDown
            (\event ->
                let
                    ( x, y ) =
                        event.pagePos
                in
                Start (Diagram.ItemMove (Diagram.TableTarget table)) ( round x, round y )
            )


tableHeaderView : Settings -> String -> Int -> Position -> Svg Msg
tableHeaderView settings headerText headerWidth ( posX, posY ) =
    g []
        [ rect
            [ width <| String.fromInt headerWidth
            , height <| String.fromInt Constants.tableRowHeight
            , x (String.fromInt posX)
            , y (String.fromInt posY)
            , fill settings.color.activity.backgroundColor
            ]
            []
        , text_
            [ x <| String.fromInt <| posX + 8
            , y <| String.fromInt <| posY + 24
            , fontFamily (fontStyle settings)
            , fill settings.color.activity.color
            , fontSize "16"
            , fontWeight "bold"
            , class ".select-none"
            ]
            [ text headerText ]
        ]


columnView : Settings -> Int -> Position -> Column -> Svg Msg
columnView settings columnWidth ( posX, posY ) (Column name_ type_ attrs) =
    let
        colX =
            String.fromInt posX

        colY =
            String.fromInt posY

        isPrimaryKey =
            find (\i -> i == PrimaryKey) attrs |> isJust

        isNull =
            find (\i -> i == Null) attrs |> isJust

        isIndex =
            find (\i -> i == Index) attrs |> isJust

        isNotNull =
            find (\i -> i == NotNull) attrs |> isJust

        style =
            if isPrimaryKey then
                [ Attr.style "font-weight" "600", Attr.style "color" settings.color.story.color ]

            else
                [ Attr.style "font-weight" "400", Attr.style "color" settings.color.label ]
    in
    g []
        [ rect
            [ width <| String.fromInt columnWidth
            , height <| String.fromInt Constants.tableRowHeight
            , x colX
            , y colY
            , fill settings.color.story.backgroundColor
            ]
            []
        , foreignObject
            [ x colX
            , y colY
            , width <| String.fromInt columnWidth
            , height <| String.fromInt Constants.tableRowHeight
            ]
            [ div
                ([ Attr.style "width" (String.fromInt columnWidth ++ "px")
                 , Attr.style "display" "flex"
                 , Attr.style "align-items" "center"
                 , Attr.style "justify-content" "space-between"
                 , Attr.style "font-size" "0.9rem"
                 , Attr.style "height" (String.fromInt Constants.tableRowHeight ++ "px")
                 , Attr.style "color" settings.color.story.color
                 ]
                    ++ style
                )
                [ div
                    [ Attr.style "margin-left" "8px"
                    ]
                    [ text name_
                    ]
                , div
                    [ Attr.style "margin-right" "8px"
                    , Attr.style "display" "flex"
                    , Attr.style "align-items" "center"
                    , Attr.style "font-size" "0.8rem"
                    ]
                    [ if isPrimaryKey then
                        div [ Attr.style "margin-right" "8px" ]
                            [ Icon.key settings.color.story.color 12
                            ]

                      else if isIndex then
                        div
                            [ Attr.style "margin-right" "8px"
                            , Attr.style "margin-top" "5px"
                            ]
                            [ Icon.search settings.color.story.color 16
                            ]

                      else
                        Empty.view
                    , text <|
                        ER.columnTypeToString type_
                            ++ (if isNull then
                                    "?"

                                else
                                    ""
                               )
                            ++ (if isNotNull then
                                    "!"

                                else
                                    ""
                               )
                    ]
                ]
            ]
        ]


relationshipView : Settings -> List Relationship -> TableViewDict -> Svg Msg
relationshipView settings relationships tables =
    g [] <|
        List.map
            (\relationship ->
                let
                    ( tableName1, tableName2 ) =
                        case relationship of
                            ManyToMany t1 t2 ->
                                ( t1, t2 )

                            OneToMany t1 t2 ->
                                ( t1, t2 )

                            ManyToOne t1 t2 ->
                                ( t1, t2 )

                            OneToOne t1 t2 ->
                                ( t1, t2 )

                            NoRelation ->
                                ( "", "" )

                    table1 =
                        Dict.get tableName1 tables

                    table2 =
                        Dict.get tableName2 tables
                in
                case ( table1, table2 ) of
                    ( Just t1, Just t2 ) ->
                        let
                            t1rel =
                                Dict.get tableName2 t1.releations

                            t2rel =
                                Dict.get tableName1 t2.releations
                        in
                        g []
                            [ pathView settings t1 t2
                            , relationLabelView settings t1 t2 (Maybe.withDefault "" t1rel)
                            , relationLabelView settings t2 t1 (Maybe.withDefault "" t2rel)
                            ]

                    _ ->
                        g [] []
            )
            relationships


getPosition : Maybe Position -> Position
getPosition pos =
    Maybe.withDefault ( 0, 0 ) pos


relationLabelView : Settings -> TableViewInfo -> TableViewInfo -> String -> Svg Msg
relationLabelView settings table1 table2 label =
    let
        ( table1OffsetX, table1OffsetY ) =
            table1.offset

        ( table2OffsetX, table2OffsetY ) =
            table2.offset

        ( tableX1, tableY1 ) =
            ( (getX <| getPosition table1.position) + table1OffsetX, (getY <| getPosition table1.position) + table1OffsetY )

        ( tableX2, tableY2 ) =
            ( (getX <| getPosition table2.position) + table2OffsetX, (getY <| getPosition table2.position) + table2OffsetY )
    in
    if tableX1 == tableX2 && tableY1 < tableY2 then
        text_
            [ x <| String.fromInt <| tableX1 + getWidth table1.size // 2 + 10
            , y <| String.fromInt <| tableY1 + getHeight table1.size + 15
            , fontFamily (fontStyle settings)
            , fill settings.color.label
            , fontSize "14"
            , fontWeight "bold"
            ]
            [ text label ]

    else if tableX1 == tableX2 && tableY1 > tableY2 then
        text_
            [ x <| String.fromInt <| tableX1 + getWidth table1.size // 2 + 10
            , y <| String.fromInt <| tableY1 - 15
            , fontFamily (fontStyle settings)
            , fill settings.color.label
            , fontSize "14"
            , fontWeight "bold"
            ]
            [ text label ]

    else if tableX1 < tableX2 && tableY1 == tableY2 then
        text_
            [ x <| String.fromInt <| tableX1 + getWidth table1.size + 10
            , y <| String.fromInt <| tableY1 + getHeight table1.size // 2 - 15
            , fontFamily (fontStyle settings)
            , fill settings.color.label
            , fontSize "14"
            , fontWeight "bold"
            ]
            [ text label ]

    else if tableX1 > tableX2 && tableY1 == tableY2 then
        text_
            [ x <| String.fromInt <| tableX1 - 15
            , y <| String.fromInt <| tableY1 + getHeight table1.size // 2 + 15
            , fontFamily (fontStyle settings)
            , fill settings.color.label
            , fontSize "14"
            , fontWeight "bold"
            ]
            [ text label ]

    else if tableX1 < tableX2 then
        text_
            [ x <| String.fromInt <| tableX1 + getWidth table1.size + 10
            , y <| String.fromInt <| tableY1 + getHeight table1.size // 2 + 15
            , fontFamily (fontStyle settings)
            , fill settings.color.label
            , fontSize "14"
            , fontWeight "bold"
            ]
            [ text label ]

    else
        text_
            [ x <| String.fromInt <| tableX1 - 15
            , y <| String.fromInt <| tableY1 + getHeight table1.size // 2 - 10
            , fontFamily (fontStyle settings)
            , fill settings.color.label
            , fontSize "14"
            , fontWeight "bold"
            ]
            [ text label ]


pathView : Settings -> TableViewInfo -> TableViewInfo -> Svg Msg
pathView settings from to =
    let
        ( fromOffsetX, fromOffsetY ) =
            from.offset

        ( toOffsetX, toOffsetY ) =
            to.offset

        fromPosition =
            Tuple.mapBoth (\x -> toFloat (x + fromOffsetX)) (\y -> toFloat (y + fromOffsetY)) (getPosition from.position)

        fromSize =
            Tuple.mapBoth toFloat toFloat from.size

        toPosition =
            Tuple.mapBoth (\x -> toFloat (x + toOffsetX)) (\y -> toFloat (y + toOffsetY)) (getPosition to.position)

        toSize =
            Tuple.mapBoth toFloat toFloat to.size
    in
    Path.view settings.color.line ( fromPosition, fromSize ) ( toPosition, toSize )
