module Models.Views.Kpt exposing (Kpt, KptItem(..), from)

import Data.Item as Item exposing (Item, Items)


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
