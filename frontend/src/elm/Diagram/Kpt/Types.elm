module Diagram.Kpt.Types exposing (Kpt, KptItem(..), from, size)

import Constants
import Diagram.Types.Settings as DiagramSettings
import Types.Item as Item exposing (Item, Items)
import Types.Size exposing (Size)
import Utils.Common as Utils


type alias Kpt =
    { keep : KptItem
    , problem : KptItem
    , try : KptItem
    }


type KptItem
    = KptItem Item


from : Items -> Kpt
from items =
    Kpt (items |> Item.getAt 0 |> Maybe.withDefault Item.new |> KptItem)
        (items |> Item.getAt 1 |> Maybe.withDefault Item.new |> KptItem)
        (items |> Item.getAt 2 |> Maybe.withDefault Item.new |> KptItem)


size : DiagramSettings.Settings -> Items -> Size
size settings items =
    ( Constants.largeItemWidth * 2 + 20, Basics.max Constants.itemHeight (Utils.getCanvasHeight settings items) * 2 + 50 )
