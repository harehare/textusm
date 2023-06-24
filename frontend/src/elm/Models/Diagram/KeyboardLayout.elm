module Models.Diagram.KeyboardLayout exposing (KeyboardLayout, Row(..), from, layout, rows)

import Models.Diagram.KeyboardLayout.Key as Key exposing (Key)
import Models.Diagram.KeyboardLayout.Layout as Layout exposing (Layout)
import Models.Item as Item exposing (Items)
import Models.Property as Property exposing (Property)


type KeyboardLayout
    = KeyboardLayout Layout (List Row)


type Row
    = Row (List Key)


from : Items -> Property -> KeyboardLayout
from items property =
    KeyboardLayout
        (Property.getKeybordLayout property
            |> Maybe.map Layout.fromString
            |> Maybe.withDefault Layout.RowStaggered
        )
        (Item.map
            (\item ->
                Item.getChildrenItems item
                    |> itemsToRow
            )
            items
        )


rows : KeyboardLayout -> List Row
rows (KeyboardLayout _ r) =
    r


layout : KeyboardLayout -> Layout
layout (KeyboardLayout l _) =
    l


itemsToRow : Items -> Row
itemsToRow items =
    Row <| Item.map Key.fromItem items
