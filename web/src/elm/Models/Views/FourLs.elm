module Models.Views.FourLs exposing (FourLs, FourLsItem(..), fromItems)

import Data.Item as Item exposing (Item, Items)


type alias FourLs =
    { liked : FourLsItem
    , learned : FourLsItem
    , lacked : FourLsItem
    , longedFor : FourLsItem
    }


type FourLsItem
    = FourLsItem Item


fromItems : Items -> FourLs
fromItems items =
    FourLs (items |> Item.getAt 0 |> Maybe.withDefault Item.emptyItem |> FourLsItem)
        (items |> Item.getAt 1 |> Maybe.withDefault Item.emptyItem |> FourLsItem)
        (items |> Item.getAt 2 |> Maybe.withDefault Item.emptyItem |> FourLsItem)
        (items |> Item.getAt 3 |> Maybe.withDefault Item.emptyItem |> FourLsItem)
