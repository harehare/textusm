module Diagram.ImpactMap.Types exposing (size)

import Diagram.Types.CardSize as CardSize
import Diagram.Types.Settings as DiagramSettings
import Types.Item as Item exposing (Items)
import Types.Size exposing (Size)


size : DiagramSettings.Settings -> Items -> Int -> Size
size settings items hierarchy =
    ( (CardSize.toInt settings.size.width + 24) * ((hierarchy + 1) * 2) + 100
    , case Item.head items of
        Just head ->
            Item.getLeafCount head * (CardSize.toInt settings.size.height + 24) * 2

        Nothing ->
            0
    )
