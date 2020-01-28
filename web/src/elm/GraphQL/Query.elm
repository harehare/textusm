module GraphQL.Query exposing (item, items)

import GraphQL.Models.DiagramItem as DiagramItem exposing (DiagramItem)
import Graphql.Operation exposing (RootQuery)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet, hardcoded, with)
import TextUSM.Object.Item
import TextUSM.Query as Query
import TextUSM.Scalar exposing (Id(..))


item : String -> SelectionSet DiagramItem RootQuery
item id =
    Query.item { id = id } <|
        (SelectionSet.succeed DiagramItem
            |> with (TextUSM.Object.Item.id |> DiagramItem.idToString)
            |> with TextUSM.Object.Item.text
            |> with TextUSM.Object.Item.diagram
            |> with TextUSM.Object.Item.title
            |> with TextUSM.Object.Item.thumbnail
            |> with TextUSM.Object.Item.isPublic
            |> with TextUSM.Object.Item.isBookmark
            |> hardcoded True
            |> with (TextUSM.Object.Item.createdAt |> DiagramItem.mapToDateTime)
            |> with (TextUSM.Object.Item.updatedAt |> DiagramItem.mapToDateTime)
        )


items : ( Int, Int ) -> Bool -> Bool -> SelectionSet (List (Maybe DiagramItem)) RootQuery
items ( offset, limit ) isBookmark isPublic =
    Query.items (\optionals -> { optionals | offset = Present offset, limit = Present limit, isBookmark = Present isBookmark, isPublic = Present isPublic }) <|
        (SelectionSet.succeed DiagramItem
            |> with (TextUSM.Object.Item.id |> DiagramItem.idToString)
            |> with TextUSM.Object.Item.text
            |> with TextUSM.Object.Item.diagram
            |> with TextUSM.Object.Item.title
            |> with TextUSM.Object.Item.thumbnail
            |> with TextUSM.Object.Item.isPublic
            |> with TextUSM.Object.Item.isBookmark
            |> hardcoded True
            |> with (TextUSM.Object.Item.createdAt |> DiagramItem.mapToDateTime)
            |> with (TextUSM.Object.Item.updatedAt |> DiagramItem.mapToDateTime)
        )
