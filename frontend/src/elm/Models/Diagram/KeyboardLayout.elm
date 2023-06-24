module Models.Diagram.KeyboardLayout exposing (Keyboard, from)

import Models.Item as Item exposing (Item, Items)
import Models.Property as Property exposing (Property)


type Layout
    = RowStaggered
    | ColumnStaggered
    | OrthoLinear


type alias Unit =
    Float


type alias Legend =
    String


type Keyboard
    = Keyboard Layout Rows


type Rows
    = Rows (List Row)


type Row
    = Row (List Key)


type Key
    = Key (Maybe Legend) (Maybe Legend) Unit


from : Items -> Property -> Keyboard
from items property =
    Keyboard
        (Property.getKeybordLayout property
            |> Maybe.map layoutFromString
            |> Maybe.withDefault RowStaggered
        )
        (Rows
            (Item.map
                (\item ->
                    Item.getChildrenItems item
                        |> itemsToRow
                )
                items
            )
        )


layoutFromString : String -> Layout
layoutFromString layout =
    case layout of
        "column-staggered" ->
            ColumnStaggered

        "ortho-linear" ->
            OrthoLinear

        _ ->
            RowStaggered


itemsToRow : Items -> Row
itemsToRow items =
    Row <| Item.map itemToKey items


itemToKey : Item -> Key
itemToKey item =
    case Item.getText item |> String.split "," of
        top :: bottom :: unit :: _ ->
            Key (Just top) (Just bottom) (String.toFloat unit |> Maybe.withDefault 1.0)

        [ top, bottom ] ->
            Key (Just top) (Just bottom) 1.0

        [ top ] ->
            Key (Just top) Nothing 1.0

        _ ->
            Key Nothing Nothing 1.0
