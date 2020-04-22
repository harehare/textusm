module GraphQL.Mutation exposing (bookmark, delete, save)

import GraphQL.Models.DiagramItem as DiagramItem exposing (DiagramItem)
import Graphql.Operation exposing (RootMutation)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet, hardcoded, with)
import TextUSM.InputObject exposing (InputItem)
import TextUSM.Mutation as Mutation
import TextUSM.Object.Item
import TextUSM.Scalar exposing (Id(..))


save : InputItem -> SelectionSet DiagramItem RootMutation
save input =
    Mutation.save { input = input } <|
        (SelectionSet.succeed DiagramItem
            |> with (TextUSM.Object.Item.id |> DiagramItem.idToString)
            |> with TextUSM.Object.Item.text
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


delete : String -> SelectionSet (Maybe DiagramItem) RootMutation
delete itemID =
    Mutation.delete { itemID = itemID } <|
        (SelectionSet.succeed DiagramItem
            |> with (TextUSM.Object.Item.id |> DiagramItem.idToString)
            |> with TextUSM.Object.Item.text
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


bookmark : String -> Bool -> SelectionSet (Maybe DiagramItem) RootMutation
bookmark itemID isBookmark =
    Mutation.bookmark { itemID = itemID, isBookmark = isBookmark } <|
        (SelectionSet.succeed DiagramItem
            |> with (TextUSM.Object.Item.id |> DiagramItem.idToString)
            |> with TextUSM.Object.Item.text
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
