module Models.Views.FreeForm exposing (FreeForm, from, getItems, unwrap)

import Data.Item as Item exposing (Items)


type FreeForm
    = FreeForm Items


getItems : FreeForm -> Items
getItems (FreeForm items) =
    items


from : Items -> FreeForm
from items =
    FreeForm <| Item.flatten items


unwrap : FreeForm -> Items
unwrap (FreeForm items) =
    items
