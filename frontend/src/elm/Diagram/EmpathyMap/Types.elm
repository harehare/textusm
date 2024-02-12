module Diagram.EmpathyMap.Types exposing (EmpathyMap, EmpathyMapItem(..), from, size)

import Constants
import Diagram.Types.Settings as DiagramSettings
import Types.Item as Item exposing (Item, Items)
import Types.Size exposing (Size)
import Utils.Common as Utils


type alias EmpathyMap =
    { says : EmpathyMapItem
    , thinks : EmpathyMapItem
    , does : EmpathyMapItem
    , feels : EmpathyMapItem
    }


type EmpathyMapItem
    = EmpathyMapItem Item


from : Items -> EmpathyMap
from items =
    EmpathyMap (items |> Item.getAt 0 |> Maybe.withDefault Item.new |> EmpathyMapItem)
        (items |> Item.getAt 1 |> Maybe.withDefault Item.new |> EmpathyMapItem)
        (items |> Item.getAt 2 |> Maybe.withDefault Item.new |> EmpathyMapItem)
        (items |> Item.getAt 3 |> Maybe.withDefault Item.new |> EmpathyMapItem)


size : DiagramSettings.Settings -> Items -> Size
size settings items =
    ( Constants.largeItemWidth * 2 + 20, Basics.max Constants.itemHeight (Utils.getCanvasHeight settings items) * 2 + 50 )
