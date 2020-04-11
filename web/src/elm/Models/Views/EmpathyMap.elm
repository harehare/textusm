module Models.Views.EmpathyMap exposing (EmpathyMap, EmpathyMapItem(..), fromItems)

import Models.Item as Item exposing (Item, Items)


type alias EmpathyMap =
    { says : EmpathyMapItem
    , thinks : EmpathyMapItem
    , does : EmpathyMapItem
    , feels : EmpathyMapItem
    }


type EmpathyMapItem
    = EmpathyMapItem Item


fromItems : Items -> EmpathyMap
fromItems items =
    EmpathyMap (items |> Item.getAt 0 |> Maybe.withDefault Item.emptyItem |> EmpathyMapItem)
        (items |> Item.getAt 1 |> Maybe.withDefault Item.emptyItem |> EmpathyMapItem)
        (items |> Item.getAt 2 |> Maybe.withDefault Item.emptyItem |> EmpathyMapItem)
        (items |> Item.getAt 3 |> Maybe.withDefault Item.emptyItem |> EmpathyMapItem)
