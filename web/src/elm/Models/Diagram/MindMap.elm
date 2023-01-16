module Models.Diagram.MindMap exposing (size)

import Models.Diagram.Settings as DiagramSettings
import Models.Item as Item exposing (Items)
import Models.Size exposing (Size)


size : DiagramSettings.Settings -> Items -> Int -> Size
size settings items hierarchy =
    ( (settings.size.width * 2) * (hierarchy * 2) + (settings.size.width * 2)
    , case Item.head items of
        Just head ->
            Item.getLeafCount head * (settings.size.height + 24)

        Nothing ->
            0
    )
