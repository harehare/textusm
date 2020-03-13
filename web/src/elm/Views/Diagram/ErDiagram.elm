module Views.Diagram.ErDiagram exposing (view)

import Dict as Dict exposing (Dict)
import Html exposing (div)
import Html.Attributes as Attr
import List.Extra exposing (find)
import Maybe.Extra exposing (isJust)
import Models.Diagram exposing (Model, Msg(..), Settings, fontStyle)
import Models.ER.Item as ER exposing (Attribute(..), Column(..), ColumnType(..), Index, IndexType(..), Relationship(..), Table(..))
import State as State exposing (Step(..))
import String
import Svg exposing (Svg, foreignObject, g, rect, text, text_)
import Svg.Attributes exposing (class, fill, fontFamily, fontSize, fontWeight, height, stroke, strokeWidth, transform, width, x, y)
import Views.Diagram.Path as Path
import Views.Diagram.Views exposing (Position, Size)


rowHeight : Int
rowHeight =
    40


tableMargin : Int
tableMargin =
    180


type alias TableViewInfo =
    { table : Table
    , size : Size
    , position : Position
    , releationCount : Int
    , releations : Dict String String
    }


type alias TableViewModel =
    Dict String TableViewInfo


view : Model -> Svg Msg
view model =
    let
        ( relationships, tables ) =
            ER.itemsToErDiagram model.items

        tableDict =
            tablesToDict tables
                |> adjustTablePosition relationships
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
        , fill model.settings.backgroundColor
        ]
        (relationshipView model.settings relationships tableDict
            :: (Dict.toList tableDict
                    |> List.map
                        (\( _, t ) ->
                            tableView model.settings t.position t.size t.table
                        )
               )
        )


adjustTablePosition : List Relationship -> TableViewModel -> TableViewModel
adjustTablePosition r t =
    let
        go { tablePositions, relationships } =
            if List.isEmpty relationships then
                Done tablePositions

            else
                case relationships of
                    x :: xs ->
                        case ER.relationshipToString x of
                            Just ( ( tableName1, relationString1 ), ( tableName2, relationString2 ) ) ->
                                let
                                    table1 =
                                        Dict.get tableName1 tablePositions

                                    table2 =
                                        Dict.get tableName2 tablePositions
                                in
                                case ( table1, table2 ) of
                                    ( Just t1, Just t2 ) ->
                                        let
                                            childPosition =
                                                tablePosition t1.size t2.size t1.position (t1.releationCount + 1)

                                            table1Updated =
                                                Dict.update
                                                    tableName1
                                                    (Maybe.map (\v -> { v | releationCount = t1.releationCount + 1, releations = Dict.insert tableName2 relationString1 v.releations }))
                                                    tablePositions

                                            table2Updated =
                                                Dict.update
                                                    tableName2
                                                    (Maybe.map (\v -> { v | position = childPosition, releations = Dict.insert tableName1 relationString2 v.releations }))
                                                    table1Updated
                                        in
                                        Loop
                                            { tablePositions = table2Updated
                                            , relationships = xs
                                            }

                                    _ ->
                                        Loop
                                            { tablePositions = tablePositions
                                            , relationships = xs
                                            }

                            Nothing ->
                                Loop
                                    { tablePositions = tablePositions
                                    , relationships = xs
                                    }

                    _ ->
                        Loop
                            { tablePositions = tablePositions
                            , relationships = []
                            }
    in
    State.tailRec go { relationships = r, tablePositions = t }


tablePosition : Size -> Size -> Position -> Int -> Position
tablePosition ( tableWidth1, tableHeight1 ) ( tableWidth2, tableHeight2 ) ( posX, posY ) relationCount =
    let
        n =
            if relationCount // 8 > 0 then
                relationCount // 8

            else
                1

        w =
            max tableWidth1 240 * n

        h =
            max tableHeight1 240 * n
    in
    case relationCount of
        1 ->
            ( posX, posY - h - tableHeight2 )

        2 ->
            ( posX + tableWidth1 + w, posY - h - tableHeight2 )

        3 ->
            ( posX + tableWidth1 + w, posY )

        4 ->
            ( posX + tableWidth1 + w, posY + h + tableHeight1 )

        5 ->
            ( posX, posY + h + tableHeight1 )

        6 ->
            ( posX - tableWidth2 - w, posY + tableHeight1 + h )

        7 ->
            ( posX - tableWidth1 - w, posY )

        _ ->
            ( posX - tableWidth1 - w, posY + tableHeight1 - h )


tablesToDict : List Table -> TableViewModel
tablesToDict tables =
    tables
        |> List.indexedMap
            (\i table ->
                let
                    (Table name columns _) =
                        table

                    width =
                        ER.tableWidth table

                    height =
                        rowHeight * (List.length columns + 1)

                    odd =
                        modBy 2 i

                    index =
                        i // 2
                in
                ( name
                , { table = table
                  , size = ( width, height )
                  , position =
                        ( index * (width + tableMargin)
                        , if odd == 1 then
                            height + tableMargin

                          else
                            0
                        )
                  , releationCount = 0
                  , releations = Dict.empty
                  }
                )
            )
        |> Dict.fromList


tableView : Settings -> Position -> Size -> Table -> Svg Msg
tableView settings ( posX, posY ) ( tableWidth, tableHeight ) table =
    let
        (Table tableName columns _) =
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
                (\i column -> columnView settings tableWidth ( posX, posY + rowHeight * (i + 1) ) column)
                columns
        )


tableHeaderView : Settings -> String -> Int -> Position -> Svg Msg
tableHeaderView settings headerText headerWidth ( posX, posY ) =
    g []
        [ rect
            [ width <| String.fromInt headerWidth
            , height <| String.fromInt rowHeight
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

        style =
            if isPrimaryKey then
                [ Attr.style "font-weight" "600", Attr.style "color" settings.color.story.color ]

            else
                [ Attr.style "font-weight" "400", Attr.style "color" settings.color.label ]
    in
    g []
        [ rect
            [ width <| String.fromInt columnWidth
            , height <| String.fromInt rowHeight
            , x colX
            , y colY
            , fill settings.color.story.backgroundColor
            ]
            []
        , foreignObject
            [ x colX
            , y colY
            , width <| String.fromInt columnWidth
            , height <| String.fromInt rowHeight
            ]
            [ div
                ([ Attr.style "width" (String.fromInt columnWidth ++ "px")
                 , Attr.style "display" "flex"
                 , Attr.style "align-items" "center"
                 , Attr.style "justify-content" "space-between"
                 , Attr.style "height" (String.fromInt rowHeight ++ "px")
                 , Attr.style "color" settings.color.story.color
                 ]
                    ++ style
                )
                [ div
                    [ Attr.style "margin-left" "8px"
                    ]
                    [ text name_ ]
                , div
                    [ Attr.style "margin-right" "8px" ]
                    [ text <| ER.columnTypeToString type_ ]
                ]
            ]
        ]


relationshipView : Settings -> List Relationship -> TableViewModel -> Svg Msg
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
                        pathView settings t1 t2

                    _ ->
                        g [] []
            )
            relationships
        )


pathView : Settings -> TableViewInfo -> TableViewInfo -> Svg Msg
pathView settings from to =
    let
        fromPosition =
            Tuple.mapBoth toFloat toFloat from.position

        fromSize =
            Tuple.mapBoth toFloat toFloat from.size

        toPosition =
            Tuple.mapBoth toFloat toFloat to.position

        toSize =
            Tuple.mapBoth toFloat toFloat to.size
    in
    Path.view settings ( fromPosition, fromSize ) ( toPosition, toSize )
