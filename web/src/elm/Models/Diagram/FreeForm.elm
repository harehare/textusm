module Models.Diagram.FreeForm exposing
    ( FreeForm
    , FreeFormItem(..)
    , from
    , getItems
    , unwrap
    , unwrapItem
    )

import Types.Item as Item exposing (Item, Items)


type FreeForm
    = FreeForm FreeFormItems


type alias FreeFormItems =
    List FreeFormItem


type FreeFormItem
    = Card Item
    | HorizontalLine Item
    | VerticalLine Item


getItems : FreeForm -> FreeFormItems
getItems (FreeForm items) =
    items


itemToFreeFormItem : Item -> FreeFormItem
itemToFreeFormItem item =
    if String.startsWith "---" <| String.trim <| Item.getText item then
        HorizontalLine item

    else if String.startsWith "|" <| String.trim <| Item.getText item then
        VerticalLine item

    else
        Card item


from : Items -> FreeForm
from items =
    FreeForm
        (Item.flatten items
            |> Item.map itemToFreeFormItem
        )


unwrap : FreeForm -> FreeFormItems
unwrap (FreeForm items) =
    items


unwrapItem : FreeFormItem -> Item
unwrapItem item =
    case item of
        Card item_ ->
            item_

        HorizontalLine item_ ->
            item_

        VerticalLine item_ ->
            item_
