module Models.Diagram.FourLs exposing (FourLs, FourLsItem(..), from, size)

import Constants
import Models.DiagramSettings as DiagramSettings
import Models.Item as Item exposing (Item, Items)
import Models.Size exposing (Size)
import Utils.Diagram as Utils


type alias FourLs =
    { liked : FourLsItem
    , learned : FourLsItem
    , lacked : FourLsItem
    , longedFor : FourLsItem
    }


type FourLsItem
    = FourLsItem Item


from : Items -> FourLs
from items =
    FourLs (items |> Item.getAt 0 |> Maybe.withDefault Item.new |> FourLsItem)
        (items |> Item.getAt 1 |> Maybe.withDefault Item.new |> FourLsItem)
        (items |> Item.getAt 2 |> Maybe.withDefault Item.new |> FourLsItem)
        (items |> Item.getAt 3 |> Maybe.withDefault Item.new |> FourLsItem)


size : DiagramSettings.Settings -> Items -> Size
size settings items =
    ( Constants.largeItemWidth * 2 + 20, Basics.max Constants.largeItemHeight (Utils.getCanvasHeight settings items) * 2 + 50 )
