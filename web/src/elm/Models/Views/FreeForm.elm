module Models.Views.FreeForm exposing (..)

import Data.Color as Color exposing (Color)
import Data.Item as Item exposing (Items)


type FreeForm
    = FreeForm Items


getItems : FreeForm -> Items
getItems (FreeForm items) =
    items


from : Items -> FreeForm
from items =
    FreeForm <| Item.flatten items
