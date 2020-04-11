module Views.Diagram.ER exposing (view)

import Constants
import Dict as Dict exposing (Dict)
import Html exposing (div)
import Html.Attributes as Attr
import Html.Lazy exposing (lazy3, lazy4)
import List.Extra exposing (find)
import Maybe.Extra exposing (isJust, isNothing, or)
import Models.Diagram exposing (Model, Msg(..), Settings, fontStyle)
import Models.Position exposing (Position, getX, getY)
import Models.Size exposing (Size, getWidth, getHeight)
import Models.Views.ER as ER exposing (Attribute(..), Column(..), ColumnType(..), Relationship(..), Table(..))
import State as State exposing (Step(..))
import String
import Svg exposing (Svg, foreignObject, g, rect, text, text_)
import Svg.Attributes exposing (class, fill, fontFamily, fontSize, fontWeight, height, stroke, strokeWidth, transform, width, x, y)
import Views.Diagram.Path as Path
import Views.Empty as Empty
import Views.Icon as Icon


type alias TableViewInfo =
    { table : Table
    , size : Size
    , position : Maybe Position
    , releationCount : Int
    , releations : Dict String String
    }


type alias TableViewDict =
    Dict String TableViewInfo


view : Model -> Svg Msg
view model =
    let
        ( relationships, tables ) =
            ER.fromItems model.items

        tableDict =
            tablesToDict tables
                |> adjustTablePosition relationships

        ( centerX, centerY ) =
            if model.matchParent then
                getTableTopLeft tableDict
                    |> Tuple.mapBoth toFloat toFloat

            else
                ( model.x, model.y )
    in
    g
        [ transform
            ("translate("
                ++ String.fromFloat
                    (if isInfinite <| model.x then
                        0

                     else
                        centerX + 32
                    )
                ++ ","
                ++ String.fromFloat
                    (if isInfinite <| model.y then
                        0

                     else
                        centerY + (toFloat model.height / toFloat 2)
                    )
                ++ ")"
            )
        , fill model.settings.backgroundColor
        ]
        (lazy3 relationshipView model.settings relationships tableDict
            :: (Dict.toList tableDict
                    |> List.map
                        (\( _, t ) ->
                            lazy4 tableView model.settings (getPosition t.position) t.size t.table
                        )
               )
        )


getTableTopLeft : TableViewDict -> Position
getTableTopLeft tableDict =
    let
        ( mx, my ) =
            Dict.values tableDict
                |> List.map (\p -> getPosition p.position)
                |> List.foldl
                    (\( x1, y1 ) ( minX, minY ) ->
                        ( min x1 minX, min y1 minY )
                    )
                    ( 0, 0 )
    in
    ( -mx, -my )


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
                                                calcTablePosition table1.size table2.size table1.position nextPosition (table1.releationCount + 1)

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


calcTablePosition : Size -> Size -> Maybe Position -> Maybe Position -> Int -> ( Maybe Position, Position )
calcTablePosition ( tableWidth1, tableHeight1 ) ( tableWidth2, tableHeight2 ) pos nextPosition relationCount =
    let
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
                    (Table name columns) =
                        table

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
                  }
                )
            )
        |> Dict.fromList


tableView : Settings -> Position -> Size -> Table -> Svg Msg
tableView settings ( posX, posY ) ( tableWidth, tableHeight ) table =
    let
        (Table tableName columns) =
            table
    in
    g []
        (rect
            [ width <| String.fromInt tableWidth
            , height <| String.fromInt tableHeight
            , x (String.fromInt posX)
            , y (String.fromInt posY)
            , strokeWidth "1"
            , stroke settings.color.activity.backgroundColor
            ]
            []
            :: tableHeaderView settings tableName tableWidth ( posX, posY )
            :: List.indexedMap
                (\i column -> columnView settings tableWidth ( posX, posY + Constants.tableRowHeight * (i + 1) ) column)
                columns
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
    g []
        (List.map
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
        )


getPosition : Maybe Position -> Position
getPosition pos =
    Maybe.withDefault ( 0, 0 ) pos


relationLabelView : Settings -> TableViewInfo -> TableViewInfo -> String -> Svg Msg
relationLabelView settings table1 table2 label =
    if
        (getX <| getPosition table1.position)
            == (getX <| getPosition table2.position)
            && (getY <| getPosition table1.position)
            < (getY <| getPosition table2.position)
    then
        text_
            [ x <| String.fromInt <| (getX <| getPosition table1.position) + getWidth table1.size // 2 + 10
            , y <| String.fromInt <| (getY <| getPosition table1.position) + getHeight table1.size + 15
            , fontFamily (fontStyle settings)
            , fill settings.color.label
            , fontSize "14"
            , fontWeight "bold"
            ]
            [ text label ]

    else if
        (getX <| getPosition table1.position)
            == (getX <| getPosition table2.position)
            && (getY <| getPosition table1.position)
            > (getY <| getPosition table2.position)
    then
        text_
            [ x <| String.fromInt <| (getX <| getPosition table1.position) + getWidth table1.size // 2 + 10
            , y <| String.fromInt <| (getY <| getPosition table1.position) - 15
            , fontFamily (fontStyle settings)
            , fill settings.color.label
            , fontSize "14"
            , fontWeight "bold"
            ]
            [ text label ]

    else if
        (getX <| getPosition table1.position)
            < (getX <| getPosition table2.position)
            && (getY <| getPosition table1.position)
            == (getY <| getPosition table2.position)
    then
        text_
            [ x <| String.fromInt <| (getX <| getPosition table1.position) + getWidth table1.size + 10
            , y <| String.fromInt <| (getY <| getPosition table1.position) + getHeight table1.size // 2 - 15
            , fontFamily (fontStyle settings)
            , fill settings.color.label
            , fontSize "14"
            , fontWeight "bold"
            ]
            [ text label ]

    else if
        (getX <| getPosition table1.position)
            > (getX <| getPosition table2.position)
            && (getY <| getPosition table1.position)
            == (getY <| getPosition table2.position)
    then
        text_
            [ x <| String.fromInt <| (getX <| getPosition table1.position) - 15
            , y <| String.fromInt <| (getY <| getPosition table1.position) + getHeight table1.size // 2 + 15
            , fontFamily (fontStyle settings)
            , fill settings.color.label
            , fontSize "14"
            , fontWeight "bold"
            ]
            [ text label ]

    else if
        (getX <| getPosition table1.position)
            < (getX <| getPosition table2.position)
    then
        text_
            [ x <| String.fromInt <| (getX <| getPosition table1.position) + getWidth table1.size + 10
            , y <| String.fromInt <| (getY <| getPosition table1.position) + getHeight table1.size // 2 + 15
            , fontFamily (fontStyle settings)
            , fill settings.color.label
            , fontSize "14"
            , fontWeight "bold"
            ]
            [ text label ]

    else
        text_
            [ x <| String.fromInt <| (getX <| getPosition table1.position) - 15
            , y <| String.fromInt <| (getY <| getPosition table1.position) + getHeight table1.size // 2 - 10
            , fontFamily (fontStyle settings)
            , fill settings.color.label
            , fontSize "14"
            , fontWeight "bold"
            ]
            [ text label ]


pathView : Settings -> TableViewInfo -> TableViewInfo -> Svg Msg
pathView settings from to =
    let
        fromPosition =
            Tuple.mapBoth toFloat toFloat (getPosition from.position)

        fromSize =
            Tuple.mapBoth toFloat toFloat from.size

        toPosition =
            Tuple.mapBoth toFloat toFloat (getPosition to.position)

        toSize =
            Tuple.mapBoth toFloat toFloat to.size
    in
    Path.view settings ( fromPosition, fromSize ) ( toPosition, toSize )
