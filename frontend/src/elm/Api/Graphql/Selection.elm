module Api.Graphql.Selection exposing
    ( allItemsSelection
    , gistItemSelection
    , itemSelection
    , settingsSelection
    )

import Graphql.Object
import Graphql.Object.Color
import Graphql.Object.GistItem
import Graphql.Object.Item
import Graphql.Object.Settings
import Graphql.Scalar
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet, hardcoded, with)
import Graphql.Union
import Graphql.Union.DiagramItem
import Models.Diagram.Id as DiagramId
import Models.Diagram.Item as DiagramItem exposing (DiagramItem)
import Models.Diagram.Location as DiagramLocation
import Models.Diagram.Settings as DiagramSettings
import Models.Diagram.Type as DiagramType
import Models.Text as Text
import Models.Title as Title


allItemsSelection : SelectionSet DiagramItem Graphql.Union.DiagramItem
allItemsSelection =
    Graphql.Union.DiagramItem.fragments
        { onItem = itemSelection
        , onGistItem = gistItemSelection
        }


gistItemSelection : SelectionSet DiagramItem Graphql.Object.GistItem
gistItemSelection =
    SelectionSet.succeed DiagramItem
        |> with (Graphql.Object.GistItem.id |> SelectionSet.map (\(Graphql.Scalar.Id id) -> Just <| DiagramId.fromString id))
        |> hardcoded Text.empty
        |> with (Graphql.Object.GistItem.diagram |> SelectionSet.map DiagramType.fromGraphqlValue)
        |> with (Graphql.Object.GistItem.title |> SelectionSet.map Title.fromString)
        |> with Graphql.Object.GistItem.thumbnail
        |> hardcoded False
        |> hardcoded False
        |> hardcoded (Just DiagramLocation.Gist)
        |> with (Graphql.Object.GistItem.createdAt |> DiagramItem.mapToDateTime)
        |> with (Graphql.Object.GistItem.updatedAt |> DiagramItem.mapToDateTime)


itemSelection : SelectionSet DiagramItem Graphql.Object.Item
itemSelection =
    SelectionSet.succeed DiagramItem
        |> with (Graphql.Object.Item.id |> SelectionSet.map (\(Graphql.Scalar.Id id) -> Just <| DiagramId.fromString id))
        |> hardcoded Text.empty
        |> with (Graphql.Object.Item.diagram |> SelectionSet.map DiagramType.fromGraphqlValue)
        |> with (Graphql.Object.Item.title |> SelectionSet.map Title.fromString)
        |> with Graphql.Object.Item.thumbnail
        |> with Graphql.Object.Item.isPublic
        |> with Graphql.Object.Item.isBookmark
        |> hardcoded (Just DiagramLocation.Remote)
        |> with (Graphql.Object.Item.createdAt |> DiagramItem.mapToDateTime)
        |> with (Graphql.Object.Item.updatedAt |> DiagramItem.mapToDateTime)


settingsSelection : SelectionSet DiagramSettings.Settings Graphql.Object.Settings
settingsSelection =
    SelectionSet.succeed DiagramSettings.Settings
        |> with Graphql.Object.Settings.font
        |> with (SelectionSet.map2 (\w h -> { width = w, height = h }) Graphql.Object.Settings.width Graphql.Object.Settings.height)
        |> with
            (SelectionSet.succeed DiagramSettings.ColorSettings
                |> with (Graphql.Object.Settings.activityColor colorSelection)
                |> with (Graphql.Object.Settings.taskColor colorSelection)
                |> with (Graphql.Object.Settings.storyColor colorSelection)
                |> with Graphql.Object.Settings.lineColor
                |> with Graphql.Object.Settings.labelColor
                |> with Graphql.Object.Settings.textColor
            )
        |> with Graphql.Object.Settings.backgroundColor
        |> with Graphql.Object.Settings.zoomControl
        |> with Graphql.Object.Settings.scale
        |> with Graphql.Object.Settings.toolbar


colorSelection : SelectionSet DiagramSettings.Color Graphql.Object.Color
colorSelection =
    SelectionSet.succeed DiagramSettings.Color
        |> with Graphql.Object.Color.foregroundColor
        |> with Graphql.Object.Color.backgroundColor
