module Models.Diagram.FreeForm exposing
    ( FreeForm
    , FreeFormItem(..)
    , FreeFormItems
    , from
    , getItems
    , size
    )

import Models.Diagram.Settings as DiagramSettings
import Models.Item as Item exposing (Item, Items)
import Models.Item.Settings as ItemSettings
import Models.Size exposing (Size)


type FreeForm
    = FreeForm FreeFormItems


type FreeFormItem
    = Card Item
    | HorizontalLine Item
    | VerticalLine Item
    | Canvas Item
    | Text Item


type alias FreeFormItems =
    List FreeFormItem


from : Items -> FreeForm
from items =
    FreeForm
        (items
            |> Item.map itemToFreeFormItem
            |> List.concat
        )


getItems : FreeForm -> FreeFormItems
getItems (FreeForm items) =
    items


size : DiagramSettings.Settings -> FreeForm -> Size
size settings freeForm =
    let
        freeFormHeight : Int
        freeFormHeight =
            List.map
                (\( _, h ) ->
                    h
                )
                positionList
                |> List.maximum
                |> Maybe.withDefault 0

        freeFormWidth : Int
        freeFormWidth =
            List.map
                (\( w, _ ) ->
                    w
                )
                positionList
                |> List.maximum
                |> Maybe.withDefault 0

        items : FreeFormItems
        items =
            freeForm
                |> unwrap

        positionList : List ( Int, Int )
        positionList =
            List.indexedMap
                (\i item ->
                    let
                        item_ : Item
                        item_ =
                            unwrapItem item

                        ( offsetX, offsetY ) =
                            Item.getOffset item_
                    in
                    ( 16 + (modBy 4 i + 1) * (settings.size.width + 32)
                    , (i // 4 + 1) * (settings.size.height + 32)
                    )
                        |> Tuple.mapBoth (\x -> x + offsetX) (\y -> y + offsetY)
                )
                items
    in
    ( freeFormWidth, freeFormHeight )


itemToFreeFormItem : Item -> FreeFormItems
itemToFreeFormItem item =
    if Item.isHorizontalLine item then
        [ HorizontalLine item ]

    else if Item.isVerticalLine item then
        [ VerticalLine item ]

    else if Item.isCanvas item then
        [ Canvas item ]

    else if Item.isText item then
        [ Text item ]

    else
        [ Card <|
            Item.withChildren
                (Item.getChildren item
                    |> Item.unwrapChildren
                    |> Item.flatten
                    |> Item.map
                        (\childItem ->
                            Item.withSettings
                                (Item.getSettings childItem
                                    |> Maybe.map
                                        (\s ->
                                            s
                                                |> ItemSettings.withOffset (Item.getOffset item)
                                                |> ItemSettings.withOffsetSize (Just <| Item.getOffsetSize item)
                                        )
                                )
                                childItem
                        )
                    |> Item.fromList
                    |> Item.childrenFromItems
                )
                item
        ]


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

        Canvas item_ ->
            item_

        Text item_ ->
            item_
