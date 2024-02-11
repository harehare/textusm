module Api.Graphql.Selection exposing
    ( allItemsSelection
    , allItemsSelectionWithText
    , gistItemSelection
    , itemSelection
    , settingsSelection
    )

import Diagram.Types.CardSize as CardSize
import Diagram.Types.Id as DiagramId
import Diagram.Types.Item as DiagramItem exposing (DiagramItem)
import Diagram.Types.Location as DiagramLocation
import Diagram.Types.Scale as Scale
import Diagram.Types.Settings as DiagramSettings
import Diagram.Types.Type as DiagramType
import Graphql.Object
import Graphql.Object.Color
import Graphql.Object.GistItem
import Graphql.Object.Item
import Graphql.Object.Settings
import Graphql.Scalar
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet, hardcoded, with)
import Graphql.Union
import Graphql.Union.DiagramItem
import Types.Color as Color
import Types.Text as Text
import Types.Title as Title


allItemsSelection : SelectionSet DiagramItem Graphql.Union.DiagramItem
allItemsSelection =
    Graphql.Union.DiagramItem.fragments
        { onItem = itemSelection
        , onGistItem = gistItemSelection
        }


allItemsSelectionWithText : SelectionSet DiagramItem Graphql.Union.DiagramItem
allItemsSelectionWithText =
    Graphql.Union.DiagramItem.fragments
        { onItem = itemSelectionWithText
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


itemSelectionWithText : SelectionSet DiagramItem Graphql.Object.Item
itemSelectionWithText =
    SelectionSet.succeed DiagramItem
        |> with (Graphql.Object.Item.id |> SelectionSet.map (\(Graphql.Scalar.Id id) -> Just <| DiagramId.fromString id))
        |> with (Graphql.Object.Item.text |> SelectionSet.map Text.fromString)
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
        |> with (SelectionSet.map2 (\w h -> { width = CardSize.fromInt w, height = CardSize.fromInt h }) Graphql.Object.Settings.width Graphql.Object.Settings.height)
        |> with
            (SelectionSet.succeed DiagramSettings.ColorSettings
                |> with (Graphql.Object.Settings.activityColor colorSelection)
                |> with (Graphql.Object.Settings.taskColor colorSelection)
                |> with (Graphql.Object.Settings.storyColor colorSelection)
                |> with (SelectionSet.map Color.fromString Graphql.Object.Settings.lineColor)
                |> with (SelectionSet.map Color.fromString Graphql.Object.Settings.labelColor)
                |> with (SelectionSet.map (Maybe.map Color.fromString) Graphql.Object.Settings.textColor)
            )
        |> with (SelectionSet.map Color.fromString Graphql.Object.Settings.backgroundColor)
        |> with Graphql.Object.Settings.zoomControl
        |> with (SelectionSet.map (Maybe.map Scale.fromFloat) Graphql.Object.Settings.scale)
        |> with Graphql.Object.Settings.toolbar
        |> with Graphql.Object.Settings.lockEditing
        |> with Graphql.Object.Settings.showGrid


colorSelection : SelectionSet DiagramSettings.ColorSetting Graphql.Object.Color
colorSelection =
    SelectionSet.succeed DiagramSettings.ColorSetting
        |> with (SelectionSet.map Color.fromString Graphql.Object.Color.foregroundColor)
        |> with (SelectionSet.map Color.fromString Graphql.Object.Color.backgroundColor)
