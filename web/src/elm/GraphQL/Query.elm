module GraphQL.Query exposing (ShareCondition, item, items, shareCondition, shareItem)

import Data.DiagramItem as DiagramItem exposing (DiagramItem)
import Data.Email as Email exposing (Email)
import Data.IpAddress as IpAddress exposing (IpAddress)
import Data.Text as Text
import Data.Title as Title
import Graphql.Operation exposing (RootQuery)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet, hardcoded, with)
import Route exposing (Route(..))
import TextUSM.Object.Item
import TextUSM.Object.ShareCondition
import TextUSM.Query as Query
import TextUSM.Scalar exposing (Id(..))


type alias ShareCondition =
    { allowIPList : List IpAddress
    , allowEmail : List Email
    , token : String
    , expireTime : Int
    }


item : String -> Bool -> SelectionSet DiagramItem RootQuery
item id isPublic =
    Query.item (\optionals -> { optionals | isPublic = Present isPublic }) { id = id } <|
        (SelectionSet.succeed DiagramItem
            |> with (TextUSM.Object.Item.id |> DiagramItem.idToString)
            |> with (TextUSM.Object.Item.text |> SelectionSet.map (\value -> Text.fromString value))
            |> with TextUSM.Object.Item.diagram
            |> with (TextUSM.Object.Item.title |> SelectionSet.map (\value -> Title.fromString value))
            |> hardcoded Nothing
            |> with TextUSM.Object.Item.isPublic
            |> with TextUSM.Object.Item.isBookmark
            |> hardcoded True
            |> with TextUSM.Object.Item.tags
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
            |> with (TextUSM.Object.Item.title |> SelectionSet.map (\value -> Title.fromString value))
            |> with TextUSM.Object.Item.thumbnail
            |> with TextUSM.Object.Item.isPublic
            |> with TextUSM.Object.Item.isBookmark
            |> hardcoded True
            |> with TextUSM.Object.Item.tags
            |> with (TextUSM.Object.Item.createdAt |> DiagramItem.mapToDateTime)
            |> with (TextUSM.Object.Item.updatedAt |> DiagramItem.mapToDateTime)
        )


shareItem : String -> Maybe String -> SelectionSet DiagramItem RootQuery
shareItem token password =
    Query.shareItem
        (\optionals ->
            { optionals
                | password =
                    case password of
                        Just p ->
                            Present p

                        Nothing ->
                            Null
            }
        )
        { token = token }
    <|
        (SelectionSet.succeed DiagramItem
            |> with (TextUSM.Object.Item.id |> DiagramItem.idToString)
            |> with (TextUSM.Object.Item.text |> SelectionSet.map (\value -> Text.fromString value))
            |> with TextUSM.Object.Item.diagram
            |> with (TextUSM.Object.Item.title |> SelectionSet.map (\value -> Title.fromString value))
            |> hardcoded Nothing
            |> with TextUSM.Object.Item.isPublic
            |> with TextUSM.Object.Item.isBookmark
            |> hardcoded True
            |> hardcoded Nothing
            |> with (TextUSM.Object.Item.createdAt |> DiagramItem.mapToDateTime)
            |> with (TextUSM.Object.Item.updatedAt |> DiagramItem.mapToDateTime)
        )


shareCondition : String -> SelectionSet (Maybe ShareCondition) RootQuery
shareCondition id =
    Query.shareCondition { id = Id id } <|
        (SelectionSet.succeed ShareCondition
            |> with
                (TextUSM.Object.ShareCondition.allowIPList
                    |> SelectionSet.map
                        (\v ->
                            Maybe.withDefault [] v
                                |> List.filterMap IpAddress.fromString
                        )
                )
            |> with
                (TextUSM.Object.ShareCondition.allowEmailList
                    |> SelectionSet.map
                        (\v ->
                            Maybe.withDefault [] v
                                |> List.filterMap Email.fromString
                        )
                )
            |> with TextUSM.Object.ShareCondition.token
            |> with TextUSM.Object.ShareCondition.expireTime
        )
