module Api.Mutation exposing
    ( bookmark
    , delete
    , deleteGist
    , save
    , saveGist
    , saveSettings
    , share
    )

import Api.Selection as Selection
import Graphql.Enum.Diagram exposing (Diagram)
import Graphql.InputObject exposing (InputGistItem, InputItem, InputSettings, InputShareItem)
import Graphql.Mutation as Mutation
import Graphql.Operation exposing (RootMutation)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.Scalar exposing (GistIdScalar(..), Id(..), ItemIdScalar(..))
import Graphql.SelectionSet exposing (SelectionSet)
import Models.Diagram as DiagramModel
import Types.DiagramItem exposing (DiagramItem)


save : InputItem -> Bool -> SelectionSet DiagramItem RootMutation
save input isPublic =
    Mutation.save (\optionals -> { optionals | isPublic = Present isPublic }) { input = input } <|
        Selection.itemSelection


delete : String -> Bool -> SelectionSet ItemIdScalar RootMutation
delete itemID isPublic =
    Mutation.delete (\optionals -> { optionals | isPublic = Present isPublic }) { itemID = ItemIdScalar itemID }


bookmark : String -> Bool -> SelectionSet (Maybe DiagramItem) RootMutation
bookmark itemID isBookmark =
    Mutation.bookmark { itemID = ItemIdScalar itemID, isBookmark = isBookmark } <|
        Selection.itemSelection


share : InputShareItem -> SelectionSet String RootMutation
share input =
    Mutation.share { input = input }


saveGist : InputGistItem -> SelectionSet DiagramItem RootMutation
saveGist input =
    Mutation.saveGist { input = input } <|
        Selection.gistItemSelection


deleteGist : String -> SelectionSet GistIdScalar RootMutation
deleteGist gistID =
    Mutation.deleteGist { gistID = GistIdScalar gistID }


saveSettings : Diagram -> InputSettings -> SelectionSet DiagramModel.Settings RootMutation
saveSettings diagram input =
    Mutation.saveSettings { diagram = diagram, input = input } <|
        Selection.settingsSelection
