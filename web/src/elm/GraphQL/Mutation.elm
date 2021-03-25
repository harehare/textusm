module GraphQL.Mutation exposing (bookmark, delete, save, share)

import Data.DiagramItem as DiagramItem exposing (DiagramItem)
import Data.Text as Text
import Data.Title as Title
import Graphql.Operation exposing (RootMutation)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet, hardcoded, with)
import TextUSM.InputObject exposing (InputItem)
import TextUSM.Mutation as Mutation
import TextUSM.Object.Item
import TextUSM.Scalar exposing (Id(..))


save : InputItem -> Bool -> SelectionSet DiagramItem RootMutation
save input isPublic =
    Mutation.save (\optionals -> { optionals | isPublic = Present isPublic }) { input = input } <|
        (SelectionSet.succeed DiagramItem
            |> with (TextUSM.Object.Item.id |> DiagramItem.idToString)
            |> with (TextUSM.Object.Item.text |> SelectionSet.map (\value -> Text.fromString value))
            |> with TextUSM.Object.Item.diagram
            |> with (TextUSM.Object.Item.title |> SelectionSet.map (\value -> Title.fromString value))
            |> with TextUSM.Object.Item.thumbnail
            |> with TextUSM.Object.Item.isPublic
            |> with TextUSM.Object.Item.isBookmark
            |> hardcoded True
            |> with TextUSM.Object.Item.tags
            |> with (TextUSM.Object.Item.createdAt |> DiagramItem.mapToDateTime)
            |> with (TextUSM.Object.Item.updatedAt |> DiagramItem.mapToDateTime)
        )


delete : String -> Bool -> SelectionSet String RootMutation
delete itemID isPublic =
    Mutation.delete (\optionals -> { optionals | isPublic = Present isPublic }) { itemID = itemID }


bookmark : String -> Bool -> SelectionSet (Maybe DiagramItem) RootMutation
bookmark itemID isBookmark =
    Mutation.bookmark { itemID = itemID, isBookmark = isBookmark } <|
        (SelectionSet.succeed DiagramItem
            |> with (TextUSM.Object.Item.id |> DiagramItem.idToString)
            |> with (TextUSM.Object.Item.text |> SelectionSet.map (\value -> Text.fromString value))
            |> with TextUSM.Object.Item.diagram
            |> with (TextUSM.Object.Item.title |> SelectionSet.map (\value -> Title.fromString value))
            |> with TextUSM.Object.Item.thumbnail
            |> with TextUSM.Object.Item.isPublic
            |> with TextUSM.Object.Item.isBookmark
            |> hardcoded True
            |> with TextUSM.Object.Item.tags
            |> with (TextUSM.Object.Item.createdAt |> DiagramItem.mapToDateTime)
            |> with (TextUSM.Object.Item.updatedAt |> DiagramItem.mapToDateTime)
        )


share : String -> Int -> SelectionSet String RootMutation
share itemID expSecond =
    Mutation.share (\optionals -> { optionals | expSecond = Present expSecond }) { itemID = itemID }
