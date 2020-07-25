module GraphQL.Query exposing (item, items)

import Data.DiagramItem as DiagramItem exposing (DiagramItem)
import Data.Text as Text
import Graphql.Operation exposing (RootQuery)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet, hardcoded, with)
import TextUSM.Object.Item
import TextUSM.Query as Query
import TextUSM.Scalar exposing (Id(..))


item : String -> SelectionSet DiagramItem RootQuery
item id =
    Query.item (\optionals -> { optionals | isPublic = Present False }) { id = id } <|
        (SelectionSet.succeed DiagramItem
            |> with (TextUSM.Object.Item.id |> DiagramItem.idToString)
            |> with (TextUSM.Object.Item.text |> SelectionSet.map (\value -> Text.fromString value))
            |> with TextUSM.Object.Item.diagram
            |> with TextUSM.Object.Item.title
            |> hardcoded Nothing
            |> with TextUSM.Object.Item.isPublic
            |> with TextUSM.Object.Item.isBookmark
            |> hardcoded True
            |> hardcoded Nothing
            |> with (TextUSM.Object.Item.createdAt |> DiagramItem.mapToDateTime)
            |> with (TextUSM.Object.Item.updatedAt |> DiagramItem.mapToDateTime)
        )


items : ( Int, Int ) -> { isBookmark : Bool, isPublic : Bool } -> SelectionSet (List (Maybe DiagramItem)) RootQuery
items ( offset, limit ) params =
    Query.items (\optionals -> { optionals | offset = Present offset, limit = Present limit, isBookmark = Present params.isBookmark, isPublic = Present params.isPublic }) <|
        (SelectionSet.succeed DiagramItem
            |> with (TextUSM.Object.Item.id |> DiagramItem.idToString)
            |> hardcoded Text.empty
            |> with TextUSM.Object.Item.diagram
            |> with TextUSM.Object.Item.title
            |> with TextUSM.Object.Item.thumbnail
            |> with TextUSM.Object.Item.isPublic
            |> with TextUSM.Object.Item.isBookmark
            |> hardcoded True
            |> with TextUSM.Object.Item.tags
            |> with (TextUSM.Object.Item.createdAt |> DiagramItem.mapToDateTime)
            |> with (TextUSM.Object.Item.updatedAt |> DiagramItem.mapToDateTime)
        )
