module Models.ER.Item exposing (Attribute(..), Column(..), ColumnType(..), Index, IndexType(..), Relationship(..), Table(..), columnTypeToString, itemsToErDiagram, tableWidth)

import List.Extra exposing (getAt)
import Models.Item as Item exposing (Item, Items)


type alias Name =
    String


type alias TableName =
    String


type alias Size =
    Int


type Relationship
    = ManyToMany TableName TableName
    | OneToMany TableName TableName
    | ManyToOne TableName TableName
    | OneToOne TableName TableName
    | NoRelation


type Table
    = Table Name (List Column) (List Index)


type Column
    = Column Name ColumnType (List Attribute)


type ColumnType
    = TinyInt
    | Int
    | Float
    | Double
    | Decimal
    | Char
    | Text
    | Blob
    | VarChar Size
    | Boolean
    | Timestamp
    | Date
    | DateTime
    | Enum


type alias Index =
    { name : String
    , type_ : IndexType
    }


type IndexType
    = BTree
    | Hash
    | Gist
    | SPGist
    | GIN
    | BRIN
    | Bloom


type Attribute
    = PrimaryKey
    | NotNull
    | Unique
    | Increment
    | Default String
    | None


tableWidth : Table -> Int
tableWidth (Table name columns indexes) =
    String.length name
        :: List.map (\(Column colName _ _) -> String.length colName)
            columns
        ++ List.map
            (\index -> String.length index.name)
            indexes
        |> List.maximum
        |> Maybe.map (\maxLength -> 12 * maxLength)
        |> Maybe.withDefault 180
        |> max 180


itemsToErDiagram : Items -> ( List Relationship, List Table )
itemsToErDiagram items =
    let
        relationships =
            Item.getAt 0 items
                |> Maybe.withDefault Item.emptyItem
                |> .children
                |> Item.unwrapChildren

        tables =
            Item.getAt 1 items
                |> Maybe.withDefault Item.emptyItem
                |> .children
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
            String.trim item.text
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
        tableName =
            String.trim item.text

        items =
            Item.unwrapChildren item.children

        columns =
            Item.getAt 0 items
                |> Maybe.withDefault Item.emptyItem
                |> .children
                |> Item.unwrapChildren
                |> Item.map itemToColumn

        indexes =
            Item.getAt 1 items
                |> Maybe.withDefault Item.emptyItem
                |> .children
                |> Item.unwrapChildren
                |> Item.map itemToIndex
    in
    Table tableName columns indexes


itemToColumn : Item -> Column
itemToColumn item =
    let
        tokens =
            String.split "," item.text
                |> List.map (\i -> String.trim i)

        columnName =
            getAt 0 tokens
                |> Maybe.withDefault ""

        columnType =
            getAt 1 tokens
                |> Maybe.map textToColumnType
                |> Maybe.withDefault Int

        columnAttributes =
            List.drop 2 tokens
                |> List.map
                    textToColumnAttribute
    in
    Column columnName columnType columnAttributes


textToColumnAttribute : String -> Attribute
textToColumnAttribute text =
    let
        tokens =
            String.split ":" text
                |> List.map (\i -> String.trim i |> String.toLower)
    in
    case tokens of
        [ "pk" ] ->
            PrimaryKey

        [ "not null" ] ->
            NotNull

        [ "unique" ] ->
            Unique

        [ "increment" ] ->
            Increment

        [ "default", value ] ->
            Default value

        _ ->
            None


textToColumnType : String -> ColumnType
textToColumnType text =
    let
        tokens =
            String.split ":" text
                |> List.map (\i -> String.trim i |> String.toLower)
    in
    case tokens of
        [ "tinyint" ] ->
            TinyInt

        [ "int" ] ->
            Int

        [ "float" ] ->
            Float

        [ "double" ] ->
            Double

        [ "decimal" ] ->
            Decimal

        [ "char" ] ->
            Char

        [ "text" ] ->
            Text

        [ "blob" ] ->
            Blob

        [ "varchar", size ] ->
            VarChar <| Maybe.withDefault 255 <| String.toInt size

        [ "boolean" ] ->
            Boolean

        [ "timestamp" ] ->
            Timestamp

        [ "date" ] ->
            Date

        [ "datetime" ] ->
            DateTime

        [ "enum" ] ->
            Enum

        _ ->
            Int


itemToIndex : Item -> Index
itemToIndex item =
    let
        tokens =
            String.split "," item.text
                |> List.map (\i -> String.trim i)

        indexName =
            getAt 0 tokens
                |> Maybe.withDefault ""

        indexType =
            getAt 1 tokens
                |> Maybe.map textToIndexType
                |> Maybe.withDefault BTree
    in
    Index indexName indexType


textToIndexType : String -> IndexType
textToIndexType text =
    let
        indexType =
            String.toLower text |> String.trim
    in
    case indexType of
        "btree" ->
            BTree

        "hash" ->
            Hash

        "gist" ->
            Gist

        "spgist" ->
            SPGist

        "gin" ->
            GIN

        "brin" ->
            BRIN

        "bloom" ->
            Bloom

        _ ->
            BTree


columnTypeToString : ColumnType -> String
columnTypeToString type_ =
    case type_ of
        TinyInt ->
            "tinyint"

        Int ->
            "int"

        Float ->
            "float"

        Double ->
            "double"

        Decimal ->
            "decimal"

        Char ->
            "char"

        Text ->
            "text"

        Blob ->
            "blob"

        VarChar size ->
            "varchar(" ++ String.fromInt size ++ ")"

        Boolean ->
            "boolean"

        Timestamp ->
            "timestamp"

        Date ->
            "date"

        DateTime ->
            "datetime"

        Enum ->
            "enum"
