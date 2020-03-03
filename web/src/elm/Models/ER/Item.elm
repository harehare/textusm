module Models.ER.Item exposing (Attribute(..), Column(..), ColumnType(..), IndexType(..), Relationship, Table, itemsToErDiagram)

import List.Extra exposing (getAt)
import Models.Item as Item exposing (Item)


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


itemsToErDiagram : List Item -> ( List (Maybe Relationship), List Table )
itemsToErDiagram items =
    let
        relationships =
            getAt 0 items
                |> Maybe.withDefault Item.emptyItem
                |> .children
                |> Item.unwrapChildren

        tables =
            getAt 1 items
                |> Maybe.withDefault Item.emptyItem
                |> .children
                |> Item.unwrapChildren
    in
    ( itemsToRelationships relationships, itemsToTables tables )


itemsToRelationships : List Item -> List (Maybe Relationship)
itemsToRelationships items =
    List.map itemToRelationship items


itemToRelationship : Item -> Maybe Relationship
itemToRelationship item =
    if String.contains " < " item.text then
        case String.split " < " item.text of
            [ table1, table2 ] ->
                Just <| OneToMany table1 table2

            _ ->
                Nothing

    else if String.contains " > " item.text then
        case String.split " > " item.text of
            [ table1, table2 ] ->
                Just <| ManyToOne table1 table2

            _ ->
                Nothing

    else if String.contains " - " item.text then
        case String.split " - " item.text of
            [ table1, table2 ] ->
                Just <| OneToOne table1 table2

            _ ->
                Nothing

    else if String.contains " = " item.text then
        case String.split " = " item.text of
            [ table1, table2 ] ->
                Just <| ManyToMany table1 table2

            _ ->
                Nothing

    else
        Nothing


itemsToTables : List Item -> List Table
itemsToTables items =
    List.map itemToTable items


itemToTable : Item -> Table
itemToTable item =
    let
        tableName =
            item.text

        children =
            Item.unwrapChildren item.children

        columns =
            getAt 0 children
                |> Maybe.withDefault Item.emptyItem
                |> .children
                |> Item.unwrapChildren
                |> List.map itemToColumn

        indexes =
            getAt 1 children
                |> Maybe.withDefault Item.emptyItem
                |> .children
                |> Item.unwrapChildren
                |> List.map itemToIndex
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
