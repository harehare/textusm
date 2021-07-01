module Models.Diagram.FourLs exposing (FourLs, FourLsItem(..), from)

import Types.Item as Item exposing (Item, Items)


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
