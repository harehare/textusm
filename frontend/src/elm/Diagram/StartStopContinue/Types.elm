module Diagram.StartStopContinue.Types exposing (StartStopContinue, StartStopContinueItem(..), from, size)

import Constants
import Diagram.Types.Settings as DiagramSettings
import Types.Item as Item exposing (Item, Items)
import Types.Size exposing (Size)
import Utils.Common as Utils


type alias StartStopContinue =
    { start : StartStopContinueItem
    , stop : StartStopContinueItem
    , continue : StartStopContinueItem
    }


type StartStopContinueItem
    = StartStopContinueItem Item


from : Items -> StartStopContinue
from items =
    StartStopContinue (items |> Item.getAt 0 |> Maybe.withDefault Item.new |> StartStopContinueItem)
        (items |> Item.getAt 1 |> Maybe.withDefault Item.new |> StartStopContinueItem)
        (items |> Item.getAt 2 |> Maybe.withDefault Item.new |> StartStopContinueItem)


size : DiagramSettings.Settings -> Items -> Size
size settings items =
    ( Constants.itemWidth * 3 + 20, Basics.max Constants.itemHeight (Utils.getCanvasHeight settings items) + 50 )
