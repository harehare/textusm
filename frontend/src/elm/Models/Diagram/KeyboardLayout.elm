module Models.Diagram.KeyboardLayout exposing
    ( KeyboardLayout
    , Row(..)
    , columnSizeList
    , from
    , innerSize
    , outerSize
    , rowSizeList
    , rows
    , size
    )

import List.Extra as ListEx
import Models.Diagram.KeyboardLayout.Key as Key exposing (Key)
import Models.Diagram.KeyboardLayout.Unit as Unit exposing (Unit)
import Models.Item as Item exposing (Items)
import Models.Size exposing (Size)


type KeyboardLayout
    = KeyboardLayout (List Row)


type Row
    = Row (List Key)
    | Blank Unit


outerSize : Float
outerSize =
    54.0


innerSize : Float
innerSize =
    42.0


from : Items -> KeyboardLayout
from items =
    KeyboardLayout
        (Item.map
            (\item ->
                if Item.getChildrenCount item == 0 then
                    Item.getText item
                        |> Unit.fromString
                        |> Maybe.withDefault Unit.u1
                        |> Blank

                else
                    Item.getChildrenItems item
                        |> itemsToRow
            )
            items
        )


rowMarginTop : Row -> Float
rowMarginTop row =
    case row of
        Row keys ->
            (List.maximum
                (List.map
                    (\key ->
                        Key.marginTop key
                            |> Maybe.withDefault Unit.zero
                            |> Unit.toFloat
                    )
                    keys
                )
                |> Maybe.withDefault 0.0
            )
                * outerSize

        Blank _ ->
            0.0


rowSizeList : (Row -> Float) -> List Row -> List Float
rowSizeList marginTop rows_ =
    ListEx.scanl
        (\row acc ->
            acc
                + (case row of
                    Blank unit ->
                        Unit.toFloat unit * outerSize

                    Row _ ->
                        outerSize + marginTop row
                  )
        )
        0
        rows_


columnSizeList : Row -> List Float
columnSizeList row =
    case row of
        Blank _ ->
            []

        Row row_ ->
            ListEx.scanl
                (\key acc ->
                    acc + Unit.toFloat (Key.unit key) * outerSize
                )
                0.0
                row_


rows : KeyboardLayout -> List Row
rows (KeyboardLayout r) =
    r


itemsToRow : Items -> Row
itemsToRow items =
    Row <| Item.map Key.fromItem items


size : KeyboardLayout -> Size
size (KeyboardLayout rows_) =
    let
        width : Float
        width =
            List.concatMap columnSizeList rows_ |> List.maximum |> Maybe.withDefault 0.0

        height : Float
        height =
            rowSizeList rowMarginTop rows_ |> List.maximum |> Maybe.withDefault 0.0
    in
    ( width |> round, height |> round )
