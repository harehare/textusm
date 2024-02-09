module Diagram.MindMap.Model exposing (size)

import Diagram.CardSize as CardSize
import Diagram.Settings as DiagramSettings
import Models.Item as Item exposing (Items)
import Models.Size exposing (Size)


size : DiagramSettings.Settings -> Items -> Int -> Size
size settings items hierarchy =
    ( (CardSize.toInt settings.size.width * 2) * (hierarchy * 2) + (CardSize.toInt settings.size.width * 2)
    , case Item.head items of
        Just head ->
            Item.getLeafCount head * (CardSize.toInt settings.size.height + 24)

        Nothing ->
            0
    )
