module Models.Views.StartStopContinue exposing (StartStopContinue, StartStopContinueItem(..), from)

import Data.Item as Item exposing (Item, Items)


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
