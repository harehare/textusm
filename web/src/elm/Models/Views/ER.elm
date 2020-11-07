module Models.Views.ER exposing (Attribute(..), Column(..), ColumnType(..), ErDiagram, Relationship(..), Table(..), columnTypeToString, from, relationshipToString, tableToLineString, tableToString, tableWidth)

import Constants
import Data.Item as Item exposing (Item, Items)
import Data.Position as Position exposing (Position)
import Dict exposing (Dict)
import Dict.Extra exposing (find)
import List.Extra as ListEx exposing (getAt)
import Maybe.Extra exposing (isJust)


type alias ErDiagram =
    ( List Relationship, List Table )


type alias Name =
    String


type alias TableName =
    String


type alias RelationShipString =
    String


type alias Length =
    Int


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
        |> Maybe.map (\maxLength -> 11 * maxLength + 20)
        |> Maybe.withDefault 160
        |> max 160


from : Items -> ErDiagram
from items =
    let
        relationships =
            Item.getAt 0 items
                |> Maybe.withDefault Item.new
                |> Item.getChildren
                |> Item.unwrapChildren

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
        text =
            Item.getText item
                |> String.trim

        tableInfo =
            text
                |> String.split "|"
                |> List.map String.trim

        ( tableName, position ) =
            case tableInfo of
                [ name, xString, yString ] ->
                    let
                        maybeX =
                            String.toInt xString

                        maybeY =
                            String.toInt yString
                    in
                    ( name
                    , String.toInt xString
                        |> Maybe.andThen (\x -> Maybe.andThen (\y -> Just ( x, y )) (String.toInt yString))
                    )

                [ name, _ ] ->
                    ( name, Nothing )

                _ ->
                    ( text, Nothing )

        items =
            Item.getChildren item |> Item.unwrapChildren

        columns =
            Item.map itemToColumn items
    in
    Table tableName columns position (Item.getLineNo item)


itemToColumn : Item -> Column
itemToColumn item =
    let
        tokens =
            Item.getText item
                |> String.trim
                |> String.split " "
                |> List.map (\i -> String.trim i)

        columnName =
            getAt 0 tokens
                |> Maybe.withDefault ""

        columnType =
            getAt 1 tokens
                |> Maybe.map textToColumnType
                |> Maybe.withDefault (Int NoLimit)

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

        primaryKey =
            if isJust <| getkAttributeIndex "pk" then
                PrimaryKey

            else
                None

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

        unique =
            if isJust <| getkAttributeIndex "Unique" then
                Unique

            else
                None

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

        increment =
            if isJust <| getkAttributeIndex "increment" then
                Increment

            else
                None

        index =
            if isJust <| getkAttributeIndex "index" then
                Index

            else
                None

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
        tokens =
            String.split "(" text
                |> List.map (\i -> ( String.trim i |> String.toLower |> String.replace ")" "", String.endsWith ")" i ))
    in
    case tokens of
        [ ( "tinyint", False ) ] ->
            TinyInt NoLimit

        [ ( "tinyint", False ), ( size, True ) ] ->
            case String.toInt size of
                Just v ->
                    TinyInt (Length v)

                Nothing ->
                    TinyInt NoLimit

        [ ( "int", False ) ] ->
            Int NoLimit

        [ ( "int", False ), ( size, True ) ] ->
            case String.toInt size of
                Just v ->
                    Int (Length v)

                Nothing ->
                    Int NoLimit

        [ ( "float", False ) ] ->
            Float NoLimit

        [ ( "float", False ), ( size, True ) ] ->
            case String.toInt size of
                Just v ->
                    Float (Length v)

                Nothing ->
                    Float NoLimit

        [ ( "double", False ) ] ->
            Double NoLimit

        [ ( "double", False ), ( size, True ) ] ->
            case String.toInt size of
                Just v ->
                    Double (Length v)

                Nothing ->
                    Double NoLimit

        [ ( "decimal", False ) ] ->
            Decimal NoLimit

        [ ( "decimal", False ), ( size, True ) ] ->
            case String.toInt size of
                Just v ->
                    Decimal (Length v)

                Nothing ->
                    Decimal NoLimit

        [ ( "char", False ) ] ->
            Char NoLimit

        [ ( "char", False ), ( size, True ) ] ->
            case String.toInt size of
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

        [ ( "varchar", False ), ( size, True ) ] ->
            case String.toInt size of
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

        [ ( "datetime", False ) ] ->
            DateTime

        [ ( "enum", False ), ( values, True ) ] ->
            Enum (String.split "," values |> List.map String.trim)

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
            "datetime"

        Enum _ ->
            "enum"


tableToString : Table -> String
tableToString (Table name columns _ _) =
    let
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
        primaryKeys =
            List.filter
                (\(Column _ _ attrs) ->
                    ListEx.find (\i -> i == PrimaryKey) attrs |> isJust
                )
                columns
                |> List.map (\(Column name _ _) -> "`" ++ name ++ "`")
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
            "datetime"

        Enum values ->
            "enum(" ++ String.join "," values ++ ")"


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
