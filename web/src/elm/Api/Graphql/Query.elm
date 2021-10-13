module Api.Graphql.Query exposing
    ( ShareCondition
    , allItems
    , gistItem
    , gistItems
    , item
    , items
    , settings
    , shareCondition
    , shareItem
    )

import Api.Graphql.Selection as Selection
import Graphql.Enum.Diagram exposing (Diagram)
import Graphql.Object.GistItem
import Graphql.Object.Item
import Graphql.Object.ShareCondition
import Graphql.Operation exposing (RootQuery)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.Query as Query
import Graphql.Scalar exposing (GistIdScalar(..), ItemIdScalar(..))
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet, hardcoded, with)
import Models.Diagram as DiagramModel
import Models.DiagramItem as DiagramItem exposing (DiagramItem)
import Models.DiagramLocation as DiagramLocation
import Models.Email as Email exposing (Email)
import Models.IpAddress as IpAddress exposing (IpAddress)
import Models.Text as Text
import Models.Title as Title


type alias ShareCondition =
    { allowIPList : List IpAddress
    , allowEmail : List Email
    , token : String
    , expireTime : Int
    }


item : String -> Bool -> SelectionSet DiagramItem RootQuery
item id isPublic =
    Query.item (\optionals -> { optionals | isPublic = Present isPublic }) { id = ItemIdScalar id } <|
        (SelectionSet.succeed DiagramItem
            |> with (Graphql.Object.Item.id |> DiagramItem.idToString)
            |> with (Graphql.Object.Item.text |> SelectionSet.map (\value -> Text.fromString value))
            |> with Graphql.Object.Item.diagram
            |> with (Graphql.Object.Item.title |> SelectionSet.map (\value -> Title.fromString value))
            |> hardcoded Nothing
            |> with Graphql.Object.Item.isPublic
            |> with Graphql.Object.Item.isBookmark
            |> hardcoded True
            |> hardcoded (Just DiagramLocation.Remote)
            |> with (Graphql.Object.Item.createdAt |> DiagramItem.mapToDateTime)
            |> with (Graphql.Object.Item.updatedAt |> DiagramItem.mapToDateTime)
        )


items : ( Int, Int ) -> { isBookmark : Bool, isPublic : Bool } -> SelectionSet (List (Maybe DiagramItem)) RootQuery
items ( offset, limit ) params =
    Query.items (\optionals -> { optionals | offset = Present offset, limit = Present limit, isBookmark = Present params.isBookmark, isPublic = Present params.isPublic }) <|
        Selection.itemSelection


allItems : ( Int, Int ) -> SelectionSet (Maybe (List DiagramItem)) RootQuery
allItems ( offset, limit ) =
    Query.allItems (\optionals -> { optionals | offset = Present offset, limit = Present limit }) <|
        Selection.allItemsSelection


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
            |> with (Graphql.Object.Item.id |> DiagramItem.idToString)
            |> with (Graphql.Object.Item.text |> SelectionSet.map (\value -> Text.fromString value))
            |> with Graphql.Object.Item.diagram
            |> with (Graphql.Object.Item.title |> SelectionSet.map (\value -> Title.fromString value))
            |> hardcoded Nothing
            |> with Graphql.Object.Item.isPublic
            |> with Graphql.Object.Item.isBookmark
            |> hardcoded True
            |> hardcoded (Just DiagramLocation.Remote)
            |> with (Graphql.Object.Item.createdAt |> DiagramItem.mapToDateTime)
            |> with (Graphql.Object.Item.updatedAt |> DiagramItem.mapToDateTime)
        )


shareCondition : String -> SelectionSet (Maybe ShareCondition) RootQuery
shareCondition id =
    Query.shareCondition { id = ItemIdScalar id } <|
        (SelectionSet.succeed ShareCondition
            |> with
                (Graphql.Object.ShareCondition.allowIPList
                    |> SelectionSet.map
                        (\v ->
                            Maybe.withDefault [] v
                                |> List.filterMap IpAddress.fromString
                        )
                )
            |> with
                (Graphql.Object.ShareCondition.allowEmailList
                    |> SelectionSet.map
                        (\v ->
                            Maybe.withDefault [] v
                                |> List.filterMap Email.fromString
                        )
                )
            |> with Graphql.Object.ShareCondition.token
            |> with Graphql.Object.ShareCondition.expireTime
        )


gistItem : String -> SelectionSet DiagramItem RootQuery
gistItem id =
    Query.gistItem { id = GistIdScalar id } <|
        (SelectionSet.succeed DiagramItem
            |> with (Graphql.Object.GistItem.id |> DiagramItem.gistIdToString)
            |> hardcoded Text.empty
            |> with Graphql.Object.GistItem.diagram
            |> with (Graphql.Object.GistItem.title |> SelectionSet.map (\value -> Title.fromString value))
            |> hardcoded Nothing
            |> hardcoded False
            |> hardcoded False
            |> hardcoded True
            |> hardcoded (Just DiagramLocation.Gist)
            |> with (Graphql.Object.GistItem.createdAt |> DiagramItem.mapToDateTime)
            |> with (Graphql.Object.GistItem.updatedAt |> DiagramItem.mapToDateTime)
        )


gistItems : ( Int, Int ) -> SelectionSet (List (Maybe DiagramItem)) RootQuery
gistItems ( offset, limit ) =
    Query.gistItems (\optionals -> { optionals | offset = Present offset, limit = Present limit }) <|
        Selection.gistItemSelection


settings : Diagram -> SelectionSet DiagramModel.Settings RootQuery
settings diagram =
    Query.settings { diagram = diagram } <|
        Selection.settingsSelection
