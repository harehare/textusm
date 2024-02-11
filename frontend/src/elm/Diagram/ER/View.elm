module Diagram.ER.View exposing (docs, view)

import Constants
import Css
    exposing
        ( alignItems
        , center
        , color
        , displayFlex
        , hex
        , int
        , justifyContent
        , marginLeft
        , marginRight
        , marginTop
        , px
        , rem
        , spaceBetween
        )
import Diagram.ER.Types as ER exposing (Attribute(..), Column(..), Relationship(..), Table(..))
import Diagram.Types.Data as DiagramData
import Diagram.Types.Settings as DiagramSettings
import Diagram.Types.Type as DiagramType
import Dict exposing (Dict)
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html.Styled as Html
import Html.Styled.Attributes exposing (css)
import Html.Styled.Lazy as Lazy
import List.Extra as ListEx
import Maybe.Extra as MaybeEx
import Models.Color as Color
import Models.Diagram as Diagram
import Models.Item as Item
import Models.Position as Position exposing (Position, getX, getY)
import Models.Size exposing (Size, getHeight, getWidth)
import State exposing (Step(..))
import String
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Attributes as SvgAttr
import Utils.Utils as Utils
import Views.Diagram.Path as Path
import Views.Diagram.Views as Views
import Views.Empty as Empty
import Views.Icon as Icon


view :
    { data : DiagramData.Data
    , settings : DiagramSettings.Settings
    , moveState : Diagram.MoveState
    , windowSize : Size
    , dragStart : Views.DragStart msg
    }
    -> Svg msg
view { data, settings, moveState, windowSize, dragStart } =
    case data of
        DiagramData.ErDiagram e ->
            let
                baseDict : TableViewDict
                baseDict =
                    tablesToDict tables
                        |> adjustTablePosition relationships

                ( relationships, tables ) =
                    e

                tableDict =
                    case moveState of
                        Diagram.ItemMove target ->
                            case target of
                                Diagram.TableTarget table ->
                                    let
                                        currentTable : Maybe TableViewInfo
                                        currentTable =
                                            Dict.get name baseDict

                                        (Table name _ position _) =
                                            table
                                    in
                                    Dict.update name
                                        (\_ ->
                                            currentTable
                                                |> Maybe.map (\t -> { t | table = table, offset = position |> Maybe.withDefault Position.zero })
                                        )
                                        baseDict

                                _ ->
                                    baseDict

                        _ ->
                            baseDict
            in
            Svg.g
                []
                (Lazy.lazy3 relationshipView settings relationships tableDict
                    :: (Dict.toList tableDict
                            |> List.map
                                (\( _, t ) ->
                                    Lazy.lazy tableView
                                        { settings = settings
                                        , svgSize = windowSize
                                        , pos = getPosition t.position
                                        , tableSize = t.size
                                        , table = t.table
                                        , dragStart = dragStart
                                        }
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
                        Maybe.map
                            (\( ( tableName1, relationString1 ), ( tableName2, relationString2 ) ) ->
                                Maybe.andThen
                                    (\t1 ->
                                        Maybe.map
                                            (\t2 ->
                                                let
                                                    ( next, childPosition ) =
                                                        calcTablePosition
                                                            { tableSize1 = table1.size
                                                            , tableSize2 = table2.size
                                                            , pos = table1.position
                                                            , nextPosition = nextPosition
                                                            , relationCount = table1.releationCount + 1
                                                            }

                                                    ( ( table1, name1, rel1 ), ( table2, name2, rel2 ) ) =
                                                        if t1.releationCount >= t2.releationCount && MaybeEx.isNothing t2.position then
                                                            ( ( t1, tableName1, relationString1 ), ( t2, tableName2, relationString2 ) )

                                                        else
                                                            ( ( t2, tableName2, relationString2 ), ( t1, tableName1, relationString1 ) )

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
                                                    , nextPosition = MaybeEx.or next nextPosition
                                                    }
                                            )
                                            (Dict.get tableName2 tablePositions)
                                    )
                                    (Dict.get tableName1 tablePositions)
                                    |> Maybe.withDefault
                                        (Loop
                                            { tablePositions = tablePositions
                                            , relationships = xs
                                            , nextPosition = nextPosition
                                            }
                                        )
                            )
                            (ER.relationshipToString x)
                            |> Maybe.withDefault
                                (Loop
                                    { tablePositions = tablePositions
                                    , relationships = xs
                                    , nextPosition = nextPosition
                                    }
                                )

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
        h : Int
        h =
            max tableHeight1 Constants.tableMargin * n

        n : Int
        n =
            if relationCount // 8 > 0 then
                relationCount // 8

            else
                1

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

        ( tableWidth1, tableHeight1 ) =
            tableSize1

        ( tableWidth2, tableHeight2 ) =
            tableSize2

        w : Int
        w =
            max tableWidth1 Constants.tableMargin * n
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


columnView : DiagramSettings.Settings -> Int -> Position -> Column -> Svg msg
columnView settings columnWidth ( posX, posY ) (Column name_ type_ attrs) =
    let
        colX : String
        colX =
            String.fromInt posX

        colY : String
        colY =
            String.fromInt posY

        isNotNull : Bool
        isNotNull =
            ListEx.find (\i -> i == NotNull) attrs |> MaybeEx.isJust

        isNull : Bool
        isNull =
            ListEx.find (\i -> i == Null) attrs |> MaybeEx.isJust

        isPrimaryKey : Bool
        isPrimaryKey =
            ListEx.find (\i -> i == PrimaryKey) attrs |> MaybeEx.isJust

        style : Css.Style
        style =
            if isPrimaryKey then
                Css.batch [ Css.fontWeight <| int 600, color <| hex <| Color.toString settings.color.story.color ]

            else
                Css.batch [ Css.fontWeight <| int 400, color <| hex <| Color.toString settings.color.label ]
    in
    Svg.g []
        [ Svg.rect
            [ SvgAttr.width <| String.fromInt columnWidth
            , SvgAttr.height <| String.fromInt Constants.tableRowHeight
            , SvgAttr.x colX
            , SvgAttr.y colY
            , SvgAttr.fill <| Color.toString settings.color.story.backgroundColor
            ]
            []
        , Svg.foreignObject
            [ SvgAttr.x colX
            , SvgAttr.y colY
            , SvgAttr.width <| String.fromInt columnWidth
            , SvgAttr.height <| String.fromInt Constants.tableRowHeight
            ]
            [ Html.div
                [ css
                    [ Css.width <| px <| toFloat columnWidth
                    , Css.height <| px <| toFloat Constants.tableRowHeight
                    , displayFlex
                    , alignItems center
                    , justifyContent spaceBetween
                    , Css.fontSize <| rem 0.9
                    , color <| hex <| Color.toString settings.color.story.color
                    , style
                    ]
                ]
                [ Html.div
                    [ css [ marginLeft <| px 8 ] ]
                    [ Html.text name_ ]
                , Html.div
                    [ css [ marginRight <| px 8, displayFlex, alignItems center, Css.fontSize <| rem 0.8 ] ]
                    [ if isPrimaryKey then
                        Html.div [ css [ marginRight <| px 8 ] ]
                            [ Icon.key (Color.toString settings.color.story.color) 12 ]

                      else if ListEx.find (\i -> i == Index) attrs |> MaybeEx.isJust then
                        Html.div
                            [ css [ marginRight <| px 8, marginTop <| px 5 ] ]
                            [ Icon.search (Color.toString settings.color.story.color) 16 ]

                      else
                        Empty.view
                    , Html.text <|
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


getPosition : Maybe Position -> Position
getPosition pos =
    Maybe.withDefault ( 0, 0 ) pos


onDragStart : Views.DragStart msg -> Table -> Bool -> Svg.Attribute msg
onDragStart dragStart table isPhone =
    dragStart (Diagram.ItemMove (Diagram.TableTarget table)) isPhone


pathView : DiagramSettings.Settings -> TableViewInfo -> TableViewInfo -> Svg msg
pathView settings from to =
    let
        ( fromOffsetX, fromOffsetY ) =
            from.offset

        fromPosition : ( Float, Float )
        fromPosition =
            Tuple.mapBoth (\x -> toFloat (x + fromOffsetX)) (\y -> toFloat (y + fromOffsetY)) (getPosition from.position)

        fromSize : ( Float, Float )
        fromSize =
            Tuple.mapBoth toFloat toFloat from.size

        ( toOffsetX, toOffsetY ) =
            to.offset

        toPosition : ( Float, Float )
        toPosition =
            Tuple.mapBoth (\x -> toFloat (x + toOffsetX)) (\y -> toFloat (y + toOffsetY)) (getPosition to.position)

        toSize : ( Float, Float )
        toSize =
            Tuple.mapBoth toFloat toFloat to.size
    in
    Path.view settings.color.line ( fromPosition, fromSize ) ( toPosition, toSize )


relationLabelView : DiagramSettings.Settings -> TableViewInfo -> TableViewInfo -> String -> Svg msg
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
        Svg.text_
            [ SvgAttr.x <| String.fromInt <| tableX1 + getWidth table1.size // 2 + 10
            , SvgAttr.y <| String.fromInt <| tableY1 + getHeight table1.size + 15
            , SvgAttr.fontFamily (DiagramSettings.fontStyle settings)
            , SvgAttr.fill <| Color.toString settings.color.label
            , SvgAttr.fontSize "14"
            , SvgAttr.fontWeight "bold"
            ]
            [ Svg.text label ]

    else if tableX1 == tableX2 && tableY1 > tableY2 then
        Svg.text_
            [ SvgAttr.x <| String.fromInt <| tableX1 + getWidth table1.size // 2 + 10
            , SvgAttr.y <| String.fromInt <| tableY1 - 15
            , SvgAttr.fontFamily (DiagramSettings.fontStyle settings)
            , SvgAttr.fill <| Color.toString settings.color.label
            , SvgAttr.fontSize "14"
            , SvgAttr.fontWeight "bold"
            ]
            [ Svg.text label ]

    else if tableX1 < tableX2 && tableY1 == tableY2 then
        Svg.text_
            [ SvgAttr.x <| String.fromInt <| tableX1 + getWidth table1.size + 10
            , SvgAttr.y <| String.fromInt <| tableY1 + getHeight table1.size // 2 - 15
            , SvgAttr.fontFamily (DiagramSettings.fontStyle settings)
            , SvgAttr.fill <| Color.toString settings.color.label
            , SvgAttr.fontSize "14"
            , SvgAttr.fontWeight "bold"
            ]
            [ Svg.text label ]

    else if tableX1 > tableX2 && tableY1 == tableY2 then
        Svg.text_
            [ SvgAttr.x <| String.fromInt <| tableX1 - 15
            , SvgAttr.y <| String.fromInt <| tableY1 + getHeight table1.size // 2 + 15
            , SvgAttr.fontFamily (DiagramSettings.fontStyle settings)
            , SvgAttr.fill <| Color.toString settings.color.label
            , SvgAttr.fontSize "14"
            , SvgAttr.fontWeight "bold"
            ]
            [ Svg.text label ]

    else if tableX1 < tableX2 then
        Svg.text_
            [ SvgAttr.x <| String.fromInt <| tableX1 + getWidth table1.size + 10
            , SvgAttr.y <| String.fromInt <| tableY1 + getHeight table1.size // 2 + 15
            , SvgAttr.fontFamily (DiagramSettings.fontStyle settings)
            , SvgAttr.fill <| Color.toString settings.color.label
            , SvgAttr.fontSize "14"
            , SvgAttr.fontWeight "bold"
            ]
            [ Svg.text label ]

    else
        Svg.text_
            [ SvgAttr.x <| String.fromInt <| tableX1 - 15
            , SvgAttr.y <| String.fromInt <| tableY1 + getHeight table1.size // 2 - 10
            , SvgAttr.fontFamily (DiagramSettings.fontStyle settings)
            , SvgAttr.fill <| Color.toString settings.color.label
            , SvgAttr.fontSize "14"
            , SvgAttr.fontWeight "bold"
            ]
            [ Svg.text label ]


relationshipView : DiagramSettings.Settings -> List Relationship -> TableViewDict -> Svg msg
relationshipView settings relationships tables =
    Svg.g [] <|
        List.map
            (\relationship ->
                let
                    table1 : Maybe TableViewInfo
                    table1 =
                        Dict.get tableName1 tables

                    table2 : Maybe TableViewInfo
                    table2 =
                        Dict.get tableName2 tables

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
                in
                case ( table1, table2 ) of
                    ( Just t1, Just t2 ) ->
                        let
                            t1Rel : Maybe String
                            t1Rel =
                                Dict.get tableName2 t1.releations

                            t2Rel : Maybe String
                            t2Rel =
                                Dict.get tableName1 t2.releations
                        in
                        Svg.g []
                            [ pathView settings t1 t2
                            , relationLabelView settings t1 t2 (Maybe.withDefault "" t1Rel)
                            , relationLabelView settings t2 t1 (Maybe.withDefault "" t2Rel)
                            ]

                    _ ->
                        Svg.g [] []
            )
            relationships


tableHeaderView : DiagramSettings.Settings -> String -> Int -> Position -> Svg msg
tableHeaderView settings headerText headerWidth ( posX, posY ) =
    Svg.g []
        [ Svg.rect
            [ SvgAttr.width <| String.fromInt headerWidth
            , SvgAttr.height <| String.fromInt Constants.tableRowHeight
            , SvgAttr.x (String.fromInt posX)
            , SvgAttr.y (String.fromInt posY)
            , SvgAttr.fill <| Color.toString settings.color.activity.backgroundColor
            ]
            []
        , Svg.text_
            [ SvgAttr.x <| String.fromInt <| posX + 8
            , SvgAttr.y <| String.fromInt <| posY + 24
            , SvgAttr.fontFamily (DiagramSettings.fontStyle settings)
            , SvgAttr.fill <| Color.toString settings.color.activity.color
            , SvgAttr.fontSize "16"
            , SvgAttr.fontWeight "bold"
            ]
            [ Svg.text headerText ]
        ]


tableView :
    { settings : DiagramSettings.Settings
    , svgSize : Size
    , pos : Position
    , tableSize : Size
    , table : Table
    , dragStart : Views.DragStart msg
    }
    -> Svg msg
tableView { settings, svgSize, pos, tableSize, table, dragStart } =
    let
        (Table tableName columns position _) =
            table

        tableX : Int
        tableX =
            getX pos + getX (position |> Maybe.withDefault Position.zero)

        tableY : Int
        tableY =
            getY pos + getY (position |> Maybe.withDefault Position.zero)
    in
    Svg.g
        [ onDragStart dragStart table (Utils.isPhone (getWidth svgSize)) ]
        (Svg.rect
            [ SvgAttr.width <| String.fromInt <| getWidth tableSize
            , SvgAttr.height <| String.fromInt <| getHeight tableSize
            , SvgAttr.x (String.fromInt tableX)
            , SvgAttr.y (String.fromInt tableY)
            , SvgAttr.strokeWidth "1"
            , SvgAttr.stroke <| Color.toString settings.color.activity.backgroundColor
            ]
            []
            :: tableHeaderView settings tableName (getWidth tableSize) ( tableX, tableY )
            :: List.indexedMap
                (\i column -> columnView settings (getWidth tableSize) ( tableX, tableY + Constants.tableRowHeight * (i + 1) ) column)
                columns
        )


type alias TableViewDict =
    Dict String TableViewInfo


type alias TableViewInfo =
    { table : Table
    , size : Size
    , position : Maybe Position
    , releationCount : Int
    , releations : Dict String String
    , offset : Position
    }


tablesToDict : List Table -> TableViewDict
tablesToDict tables =
    tables
        |> List.map
            (\table ->
                let
                    (Table name columns position _) =
                        table

                    height : Int
                    height =
                        Constants.tableRowHeight * (List.length columns + 1)

                    offsetX : Int
                    offsetX =
                        getX (position |> Maybe.withDefault Position.zero)

                    offsetY : Int
                    offsetY =
                        getY (position |> Maybe.withDefault Position.zero)

                    width : Int
                    width =
                        ER.tableWidth table
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


docs : Chapter x
docs =
    Chapter.chapter "ER"
        |> Chapter.renderComponent
            (Svg.svg
                [ SvgAttr.width "100%"
                , SvgAttr.height "100%"
                , SvgAttr.viewBox "0 0 2048 2048"
                ]
                [ view
                    { data =
                        DiagramData.ErDiagram <|
                            ER.from <|
                                (DiagramType.defaultText DiagramType.ErDiagram |> Item.fromString |> Tuple.second)
                    , moveState = Diagram.NotMove
                    , windowSize = ( 100, 100 )
                    , settings = DiagramSettings.default
                    , dragStart = \_ _ -> SvgAttr.style ""
                    }
                ]
                |> Svg.toUnstyled
            )
