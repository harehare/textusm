module GraphQL.Query exposing (item, items)

import GraphQL.Models exposing (Item)
import Graphql.Operation exposing (RootQuery)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet, hardcoded, with)
import TextUSM.Object.Item as Item
import TextUSM.Query as Query
import TextUSM.Scalar exposing (Id(..))


item : String -> SelectionSet Item RootQuery
item id =
    Query.item { id = id } <|
        (SelectionSet.succeed Item
            |> with Item.id
            |> with Item.text
            |> with Item.diagram
            |> with Item.title
            |> with Item.thumbnail
            |> with Item.isPublic
            |> with Item.isBookmark
            |> with Item.createdAt
            |> with Item.updatedAt
        )


items : ( Int, Int ) -> Bool -> Bool -> SelectionSet (List (Maybe Item)) RootQuery
items ( offset, limit ) isBookmark isPublic =
    Query.items (\optionals -> { optionals | offset = Present offset, limit = Present limit, isBookmark = Present isBookmark, isPublic = Present isPublic }) <|
        (SelectionSet.succeed Item
            |> with Item.id
            |> with Item.text
            |> with Item.diagram
            |> with Item.title
            |> hardcoded Nothing
            |> with Item.isPublic
            |> with Item.isBookmark
            |> with Item.createdAt
            |> with Item.updatedAt
        )
