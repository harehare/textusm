module GraphQL.Mutation exposing (delete, save)

import GraphQL.Models exposing (Item)
import Graphql.Operation exposing (RootMutation)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet, with)
import TextUSM.InputObject exposing (InputItem)
import TextUSM.Mutation as Mutation
import TextUSM.Object.Item as Item
import TextUSM.Scalar exposing (Id(..))


save : InputItem -> SelectionSet Item RootMutation
save input =
    Mutation.save { input = input } <|
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


delete : String -> SelectionSet (Maybe Item) RootMutation
delete itemID =
    Mutation.delete { itemID = itemID } <|
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
