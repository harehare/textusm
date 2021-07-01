module Api.Mutation exposing (bookmark, delete, save, share)

import Graphql.InputObject exposing (InputItem, InputShareItem)
import Graphql.Mutation as Mutation
import Graphql.Object.Item
import Graphql.Operation exposing (RootMutation)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.Scalar exposing (Id(..), ItemIdScalar(..))
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet, hardcoded, with)
import Types.DiagramItem as DiagramItem exposing (DiagramItem)
import Types.Text as Text
import Types.Title as Title


save : InputItem -> Bool -> SelectionSet DiagramItem RootMutation
save input isPublic =
    Mutation.save (\optionals -> { optionals | isPublic = Present isPublic }) { input = input } <|
        (SelectionSet.succeed DiagramItem
            |> with (Graphql.Object.Item.id |> DiagramItem.idToString)
            |> with (Graphql.Object.Item.text |> SelectionSet.map Text.fromString)
            |> with Graphql.Object.Item.diagram
            |> with (Graphql.Object.Item.title |> SelectionSet.map Title.fromString)
            |> with Graphql.Object.Item.thumbnail
            |> with Graphql.Object.Item.isPublic
            |> with Graphql.Object.Item.isBookmark
            |> hardcoded True
            |> with Graphql.Object.Item.tags
            |> with (Graphql.Object.Item.createdAt |> DiagramItem.mapToDateTime)
            |> with (Graphql.Object.Item.updatedAt |> DiagramItem.mapToDateTime)
        )


delete : String -> Bool -> SelectionSet ItemIdScalar RootMutation
delete itemID isPublic =
    Mutation.delete (\optionals -> { optionals | isPublic = Present isPublic }) { itemID = ItemIdScalar itemID }


bookmark : String -> Bool -> SelectionSet (Maybe DiagramItem) RootMutation
bookmark itemID isBookmark =
    Mutation.bookmark { itemID = ItemIdScalar itemID, isBookmark = isBookmark } <|
        (SelectionSet.succeed DiagramItem
            |> with (Graphql.Object.Item.id |> DiagramItem.idToString)
            |> with (Graphql.Object.Item.text |> SelectionSet.map (\value -> Text.fromString value))
            |> with Graphql.Object.Item.diagram
            |> with (Graphql.Object.Item.title |> SelectionSet.map (\value -> Title.fromString value))
            |> with Graphql.Object.Item.thumbnail
            |> with Graphql.Object.Item.isPublic
            |> with Graphql.Object.Item.isBookmark
            |> hardcoded True
            |> with Graphql.Object.Item.tags
            |> with (Graphql.Object.Item.createdAt |> DiagramItem.mapToDateTime)
            |> with (Graphql.Object.Item.updatedAt |> DiagramItem.mapToDateTime)
        )


share : InputShareItem -> SelectionSet String RootMutation
share input =
    Mutation.share { input = input }
