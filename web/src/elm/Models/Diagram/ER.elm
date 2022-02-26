module Models.Diagram.ER exposing
    ( Attribute(..)
    , Column(..)
    , ColumnLength
    , ColumnType(..)
    , ErDiagram
    , LineNo
    , Name
    , RelationShipString
    , Relationship(..)
    , Table(..)
    , TableName
    , columnTypeToString
    , from
    , relationshipToString
    , size
    , tableToLineString
    , tableToString
    , tableWidth
    , toMermaidString
    )

import Constants
import Dict exposing (Dict)
import Dict.Extra exposing (find)
import List.Extra as ListEx exposing (getAt)
import Maybe.Extra exposing (isJust)
import Models.Item as Item exposing (Item, Items)
import Models.Position as Position exposing (Position)
import Models.Size exposing (Size)


type alias ErDiagram =
    ( List Relationship, List Table )


type alias Name =
    String


type alias TableName =
    String


type alias RelationShipString =
    String


type alias LineNo =
    Int


type Relationship
    = ManyToMany TableName TableName
    | OneToMany TableName TableName
    | ManyToOne TableName TableName
    | OneToOne TableName TableName
    | NoRelation


type Table
    = Table Name (List Column) (Maybe Position) LineNo


type Column
    = Column Name ColumnType (List Attribute)


type ColumnType
    = TinyInt ColumnLength
    | Int ColumnLength
    | Float ColumnLength
    | Double ColumnLength
    | Decimal ColumnLength
    | Char ColumnLength
    | Text
    | Blob
    | VarChar ColumnLength
    | Boolean
    | Timestamp
    | Date
    | DateTime
    | Enum (List String)
    | Json


type ColumnLength
    = Length Int
    | NoLimit


type Attribute
    = PrimaryKey
    | NotNull
    | Null
    | Unique
    | Increment
    | Default String
    | Index
    | None


tableWidth : Table -> Int
tableWidth (Table name columns _ _) =
    String.length name
        :: List.map (\(Column colName _ _) -> String.length colName)
            columns
        |> List.maximum
        |> Maybe.map (\maxLength -> 14 * maxLength + 20)
        |> Maybe.withDefault 180
        |> max 180


from : Items -> ErDiagram
from items =
    let
        relationships : Items
        relationships =
            Item.getAt 0 items
                |> Maybe.withDefault Item.new
                |> Item.getChildren
                |> Item.unwrapChildren

        tables : Items
        tables =
            Item.getAt 1 items
                |> Maybe.withDefault Item.new
                |> Item.getChildren
                |> Item.unwrapChildren
    in
    ( itemsToRelationships relationships, itemsToTables tables )


itemsToRelationships : Items -> List Relationship
itemsToRelationships items =
    Item.map itemToRelationship items


itemToRelationship : Item -> Relationship
itemToRelationship item =
    let
        text : String
        text =
            Item.getText item |> String.trim
    in
    if String.contains " < " text then
        case String.split " < " text of
            [ table1, table2 ] ->
                OneToMany table1 table2

            _ ->
                NoRelation

    else if String.contains " > " text then
        case String.split " > " text of
            [ table1, table2 ] ->
                ManyToOne table1 table2

            _ ->
                NoRelation

    else if String.contains " - " text then
        case String.split " - " text of
            [ table1, table2 ] ->
                OneToOne table1 table2

            _ ->
                NoRelation

    else if String.contains " = " text then
        case String.split " = " text of
            [ table1, table2 ] ->
                ManyToMany table1 table2

            _ ->
                NoRelation

    else
        NoRelation


itemsToTables : Items -> List Table
itemsToTables items =
    Item.map itemToTable items


itemToTable : Item -> Table
itemToTable item =
    let
        text : String
        text =
            Item.getText item
                |> String.trim

        tableInfo : List String
        tableInfo =
            text
                |> String.split "|"
                |> List.map String.trim

        ( tableName, position ) =
            case tableInfo of
                [ name, xString, yString ] ->
                    ( name
                    , String.toInt xString
                        |> Maybe.andThen (\x -> Maybe.andThen (\y -> Just ( x, y )) (String.toInt yString))
                    )

                [ name, _ ] ->
                    ( name, Nothing )

                _ ->
                    ( text, Nothing )

        items : Items
        items =
            Item.getChildren item |> Item.unwrapChildren

        columns : List Column
        columns =
            Item.map itemToColumn items
    in
    Table tableName columns position (Item.getLineNo item)


itemToColumn : Item -> Column
itemToColumn item =
    let
        tokens : List String
        tokens =
            Item.getText item
                |> String.trim
                |> String.split " "
                |> List.map (\i -> String.trim i)

        columnName : String
        columnName =
            getAt 0 tokens
                |> Maybe.withDefault ""

        columnType : ColumnType
        columnType =
            getAt 1 tokens
                |> Maybe.map textToColumnType
                |> Maybe.withDefault (Int NoLimit)

        columnAttributes : List Attribute
        columnAttributes =
            List.drop 2 tokens
                |> List.indexedMap (\i v -> ( String.toLower v, i ))
                |> Dict.fromList
                |> textToColumnAttribute
    in
    Column columnName columnType columnAttributes


textToColumnAttribute : Dict String Int -> List Attribute
textToColumnAttribute attrDict =
    let
        getkAttributeIndex : String -> Maybe Int
        getkAttributeIndex attrName =
            Dict.get attrName attrDict

        primaryKey : Attribute
        primaryKey =
            if isJust <| getkAttributeIndex "pk" then
                PrimaryKey

            else
                None

        notNull : Attribute
        notNull =
            getkAttributeIndex "not"
                |> Maybe.andThen
                    (\no ->
                        getkAttributeIndex "null"
                            |> Maybe.andThen
                                (\nu ->
                                    if nu - no == 1 then
                                        Just NotNull

                                    else
                                        Nothing
                                )
                    )
                |> Maybe.withDefault None

        unique : Attribute
        unique =
            if isJust <| getkAttributeIndex "Unique" then
                Unique

            else
                None

        null : Attribute
        null =
            getkAttributeIndex "null"
                |> Maybe.andThen
                    (\_ ->
                        if isJust <| getkAttributeIndex "not" then
                            Nothing

                        else
                            Just Null
                    )
                |> Maybe.withDefault None

        increment : Attribute
        increment =
            if isJust <| getkAttributeIndex "increment" then
                Increment

            else
                None

        index : Attribute
        index =
            if isJust <| getkAttributeIndex "index" then
                Index

            else
                None

        default : Attribute
        default =
            getkAttributeIndex "default"
                |> Maybe.andThen
                    (\d ->
                        find (\_ value -> value == d + 1) attrDict
                            |> Maybe.andThen
                                (\( k, _ ) ->
                                    Just <| Default k
                                )
                    )
                |> Maybe.withDefault None
    in
    [ primaryKey, notNull, unique, increment, default, index, null ]


textToColumnType : String -> ColumnType
textToColumnType text =
    let
        tokens : List ( String, Bool )
        tokens =
            String.split "(" text
                |> List.map (\i -> ( String.trim i |> String.toLower |> String.replace ")" "", String.endsWith ")" i ))
    in
    case tokens of
        [ ( "tinyint", False ) ] ->
            TinyInt NoLimit

        [ ( "tinyint", False ), ( size_, True ) ] ->
            case String.toInt size_ of
                Just v ->
                    TinyInt (Length v)

                Nothing ->
                    TinyInt NoLimit

        [ ( "int", False ) ] ->
            Int NoLimit

        [ ( "int", False ), ( size_, True ) ] ->
            case String.toInt size_ of
                Just v ->
                    Int (Length v)

                Nothing ->
                    Int NoLimit

        [ ( "float", False ) ] ->
            Float NoLimit

        [ ( "float", False ), ( size_, True ) ] ->
            case String.toInt size_ of
                Just v ->
                    Float (Length v)

                Nothing ->
                    Float NoLimit

        [ ( "double", False ) ] ->
            Double NoLimit

        [ ( "double", False ), ( size_, True ) ] ->
            case String.toInt size_ of
                Just v ->
                    Double (Length v)

                Nothing ->
                    Double NoLimit

        [ ( "decimal", False ) ] ->
            Decimal NoLimit

        [ ( "decimal", False ), ( size_, True ) ] ->
            case String.toInt size_ of
                Just v ->
                    Decimal (Length v)

                Nothing ->
                    Decimal NoLimit

        [ ( "char", False ) ] ->
            Char NoLimit

        [ ( "char", False ), ( size_, True ) ] ->
            case String.toInt size_ of
                Just v ->
                    Char (Length v)

                Nothing ->
                    Char NoLimit

        [ ( "text", False ) ] ->
            Text

        [ ( "blob", False ) ] ->
            Blob

        [ ( "varchar", False ) ] ->
            VarChar NoLimit

        [ ( "varchar", False ), ( size_, True ) ] ->
            case String.toInt size_ of
                Just v ->
                    VarChar (Length v)

                Nothing ->
                    VarChar NoLimit

        [ ( "boolean", False ) ] ->
            Boolean

        [ ( "timestamp", False ) ] ->
            Timestamp

        [ ( "date", False ) ] ->
            Date

        [ ( "date-time", False ) ] ->
            DateTime

        [ ( "enum", False ), ( values, True ) ] ->
            Enum (String.split "," values |> List.map String.trim)

        [ ( "json", False ) ] ->
            Json

        _ ->
            Int NoLimit


relationshipToString : Relationship -> Maybe ( ( TableName, RelationShipString ), ( TableName, RelationShipString ) )
relationshipToString relationship =
    case relationship of
        ManyToMany table1 table2 ->
            Just ( ( table1, "*" ), ( table2, "*" ) )

        OneToMany table1 table2 ->
            Just ( ( table1, "1" ), ( table2, "*" ) )

        ManyToOne table1 table2 ->
            Just ( ( table1, "*" ), ( table2, "1" ) )

        OneToOne table1 table2 ->
            Just ( ( table1, "1" ), ( table2, "1" ) )

        NoRelation ->
            Nothing


columnTypeToString : ColumnType -> String
columnTypeToString type_ =
    case type_ of
        TinyInt (Length v) ->
            "tinyint(" ++ String.fromInt v ++ ")"

        TinyInt _ ->
            "tinyint"

        Int (Length v) ->
            "int(" ++ String.fromInt v ++ ")"

        Int _ ->
            "int"

        Float (Length v) ->
            "float(" ++ String.fromInt v ++ ")"

        Float _ ->
            "float"

        Double (Length v) ->
            "double(" ++ String.fromInt v ++ ")"

        Double _ ->
            "double"

        Decimal (Length v) ->
            "decimal(" ++ String.fromInt v ++ ")"

        Decimal _ ->
            "decimal"

        Char (Length v) ->
            "char(" ++ String.fromInt v ++ ")"

        Char _ ->
            "char"

        Text ->
            "text"

        Blob ->
            "blob"

        VarChar (Length v) ->
            "varchar(" ++ String.fromInt v ++ ")"

        VarChar _ ->
            "varchar"

        Boolean ->
            "boolean"

        Timestamp ->
            "timestamp"

        Date ->
            "date"

        DateTime ->
            "date-time"

        Enum _ ->
            "enum"

        Json ->
            "json"


tableToString : Table -> String
tableToString (Table name columns _ _) =
    let
        columnStrings : List String
        columnStrings =
            List.map (\c -> columnToString c |> String.trimRight) columns
    in
    "CREATE TABLE "
        ++ name
        ++ " (\n"
        ++ (primaryKeyToString columns
                |> Maybe.map
                    (\primaryKey ->
                        String.join ",\n" columnStrings ++ ",\n" ++ primaryKey
                    )
                |> Maybe.withDefault (String.join ",\n" columnStrings)
           )
        ++ "\n);\n"
        ++ (Maybe.andThen (\v -> Just <| v ++ "\n") (indexToString name columns)
                |> Maybe.withDefault ""
           )


primaryKeyToString : List Column -> Maybe String
primaryKeyToString columns =
    let
        primaryKeys : List String
        primaryKeys =
            List.filterMap
                (\(Column name _ attrs) ->
                    ListEx.find (\i -> i == PrimaryKey) attrs |> Maybe.map (\_ -> "`" ++ name ++ "`")
                )
                columns
    in
    if List.isEmpty primaryKeys then
        Nothing

    else
        Just <|
            "    PRIMARY KEY (\n"
                ++ "    "
                ++ String.join "," primaryKeys
                ++ "\n    )"


indexToString : String -> List Column -> Maybe String
indexToString tableName columns =
    let
        indexes : List Column
        indexes =
            List.filter
                (\(Column _ _ attrs) ->
                    ListEx.find (\i -> i == Index) attrs |> isJust
                )
                columns
    in
    if List.isEmpty indexes then
        Nothing

    else
        Just
            (indexes
                |> List.map
                    (\(Column name _ _) ->
                        "CREATE INDEX `idx_" ++ tableName ++ "_" ++ name ++ "` ON `" ++ tableName ++ "` (`" ++ name ++ "`);"
                    )
                |> String.join "\n"
            )


columnToString : Column -> String
columnToString (Column name type_ attrs) =
    "    `"
        ++ name
        ++ "` "
        ++ columnTypeToFullString type_
        ++ " "
        ++ String.join " " (List.map columnAttributeToString attrs |> List.filter (\v -> not <| String.isEmpty v))


columnTypeToFullString : ColumnType -> String
columnTypeToFullString type_ =
    case type_ of
        TinyInt (Length v) ->
            "tinyint(" ++ String.fromInt v ++ ")"

        TinyInt _ ->
            "tinyint"

        Int (Length v) ->
            "int(" ++ String.fromInt v ++ ")"

        Int _ ->
            "int"

        Float (Length v) ->
            "float(" ++ String.fromInt v ++ ")"

        Float _ ->
            "float"

        Double (Length v) ->
            "double(" ++ String.fromInt v ++ ")"

        Double _ ->
            "double"

        Decimal (Length v) ->
            "decimal(" ++ String.fromInt v ++ ")"

        Decimal _ ->
            "decimal"

        Char (Length v) ->
            "char(" ++ String.fromInt v ++ ")"

        Char _ ->
            "char"

        Text ->
            "text"

        Blob ->
            "blob"

        VarChar (Length v) ->
            "varchar(" ++ String.fromInt v ++ ")"

        VarChar _ ->
            "varchar"

        Boolean ->
            "boolean"

        Timestamp ->
            "timestamp"

        Date ->
            "date"

        DateTime ->
            "date-time"

        Enum values ->
            "enum(" ++ String.join "," values ++ ")"

        Json ->
            "json"


columnAttributeToString : Attribute -> String
columnAttributeToString attr =
    case attr of
        NotNull ->
            "NOT NULL"

        Null ->
            "NULL"

        Unique ->
            "UNIQUE"

        Increment ->
            "AUTO_INCREMENT"

        Default v ->
            "DEFAULT " ++ v

        _ ->
            ""


tableToLineString : Table -> String
tableToLineString (Table name _ position _) =
    let
        ( x, y ) =
            Maybe.withDefault Position.zero position
    in
    Constants.space ++ name ++ "|" ++ String.fromInt x ++ "|" ++ String.fromInt y


size : Items -> Size
size items =
    let
        ( _, tables ) =
            from items

        sizeList : List ( Int, Int )
        sizeList =
            List.map
                (\table ->
                    let
                        (Table _ columns _ _) =
                            table
                    in
                    ( tableWidth table, (List.length columns + 1) * Constants.tableRowHeight )
                )
                tables
    in
    List.foldl
        (\( w1, h1 ) ( w2, h2 ) ->
            ( w1 + w2 + Constants.tableMargin, h1 + h2 + Constants.tableMargin )
        )
        ( 0, 0 )
        sizeList



-- mermaid


toMermaidString : ErDiagram -> String
toMermaidString ( relationshipList, tableList ) =
    "erDiagram"
        :: (List.concatMap relationshipToMermaidString relationshipList
                ++ List.map tableToMermaidString tableList
                |> List.map (\line -> "    " ++ line)
           )
        |> String.join "\n"


relationshipToMermaidString : Relationship -> List String
relationshipToMermaidString relationship =
    case relationship of
        ManyToMany table1 table2 ->
            [ table1 ++ "}|..|{" ++ table2 ++ " : relation" ]

        OneToMany table1 table2 ->
            [ table1 ++ "||--o{" ++ table2 ++ " : relation" ]

        ManyToOne table1 table2 ->
            [ table1 ++ "}o--||" ++ table2 ++ " : relation" ]

        OneToOne table1 table2 ->
            [ table1 ++ "||--||" ++ table2 ++ " : relation" ]

        NoRelation ->
            []


tableToMermaidString : Table -> String
tableToMermaidString (Table name columns _ _) =
    (name ++ "{")
        :: List.map columnToMermaidString columns
        ++ [ "    }" ]
        |> String.join "\n"


columnToMermaidString : Column -> String
columnToMermaidString (Column name columnType _) =
    "        " ++ columnTypeToMermaidString columnType ++ " " ++ name


columnTypeToMermaidString : ColumnType -> String
columnTypeToMermaidString column =
    case column of
        TinyInt _ ->
            "tinyint"

        Int _ ->
            "int"

        Float _ ->
            "float"

        Double _ ->
            "double"

        Decimal _ ->
            "decimal"

        Char _ ->
            "char"

        Text ->
            "text"

        Blob ->
            "blob"

        VarChar _ ->
            "varchar"

        Boolean ->
            "boolean"

        Timestamp ->
            "Timestamp"

        Date ->
            "Date"

        DateTime ->
            "datetime"

        Enum _ ->
            "enum"

        Json ->
            "json"
