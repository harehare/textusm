module Models.Views.Kpt exposing (Kpt, KptItem(..), fromItems)

import Models.Item as Item exposing (Item, Items)


type alias Kpt =
    { keep : KptItem
    , problem : KptItem
    , try : KptItem
    }


type KptItem
    = KptItem Item


fromItems : Items -> Kpt
fromItems items =
    Kpt (items |> Item.getAt 0 |> Maybe.withDefault Item.emptyItem |> KptItem)
        (items |> Item.getAt 1 |> Maybe.withDefault Item.emptyItem |> KptItem)
        (items |> Item.getAt 2 |> Maybe.withDefault Item.emptyItem |> KptItem)
