module Api.Graphql.Mutation exposing
    ( bookmark
    , delete
    , deleteGist
    , save
    , saveGist
    , saveSettings
    , share
    )

import Api.Graphql.Selection as Selection
import Graphql.Enum.Diagram exposing (Diagram)
import Graphql.InputObject exposing (InputGistItem, InputItem, InputSettings, InputShareItem)
import Graphql.Mutation as Mutation
import Graphql.Operation exposing (RootMutation)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.Scalar
import Graphql.SelectionSet exposing (SelectionSet)
import Models.DiagramItem exposing (DiagramItem)
import Models.DiagramSettings as DiagramSettings


bookmark : String -> Bool -> SelectionSet (Maybe DiagramItem) RootMutation
bookmark itemID isBookmark =
    Mutation.bookmark { itemID = Graphql.Scalar.Id itemID, isBookmark = isBookmark } <|
        Selection.itemSelection


delete : String -> Bool -> SelectionSet Graphql.Scalar.Id RootMutation
delete itemID isPublic =
    Mutation.delete (\optionals -> { optionals | isPublic = Present isPublic }) { itemID = Graphql.Scalar.Id itemID }


deleteGist : String -> SelectionSet Graphql.Scalar.Id RootMutation
deleteGist gistID =
    Mutation.deleteGist { gistID = Graphql.Scalar.Id gistID }


save : InputItem -> Bool -> SelectionSet DiagramItem RootMutation
save input isPublic =
    Mutation.save (\optionals -> { optionals | isPublic = Present isPublic }) { input = input } <|
        Selection.itemSelection


saveGist : InputGistItem -> SelectionSet DiagramItem RootMutation
saveGist input =
    Mutation.saveGist { input = input } <|
        Selection.gistItemSelection


saveSettings : Diagram -> InputSettings -> SelectionSet DiagramSettings.Settings RootMutation
saveSettings diagram input =
    Mutation.saveSettings { diagram = diagram, input = input } <|
        Selection.settingsSelection


share : InputShareItem -> SelectionSet String RootMutation
share input =
    Mutation.share { input = input }
