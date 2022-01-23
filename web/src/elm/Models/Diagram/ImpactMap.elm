module Models.Diagram.ImpactMap exposing (size)

import Models.DiagramSettings as DiagramSettings
import Models.Item as Item exposing (Items)
import Models.Size exposing (Size)


size : DiagramSettings.Settings -> Items -> Int -> Size
size settings items hierarchy =
    ( (settings.size.width + 24) * ((hierarchy + 1) * 2) + 100
    , case Item.head items of
        Just head ->
            Item.getLeafCount head * (settings.size.height + 24) * 2

        Nothing ->
            0
    )
