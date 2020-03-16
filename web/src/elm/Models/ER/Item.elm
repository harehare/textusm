module Models.ER.Item exposing (Attribute(..), Column(..), ColumnType(..), Index, IndexType(..), Relationship(..), Table(..), columnTypeToString, itemsToErDiagram, relationshipToString, tableWidth)

import Dict exposing (Dict)
import Dict.Extra exposing (find)
import List.Extra exposing (getAt)
import Maybe.Extra exposing (isJust)
import Models.Item as Item exposing (Item, Items)


type alias Name =
    String


type alias TableName =
    String


type alias RelationShipString =
    String


type alias Length =
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
    | Null
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
            Item.map itemToColumn items

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
            item.text
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
    [ primaryKey, notNull, unique, increment, default, null ]


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
