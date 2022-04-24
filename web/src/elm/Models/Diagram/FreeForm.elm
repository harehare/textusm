module Models.Diagram.FreeForm exposing
    ( FreeForm
    , FreeFormItem(..)
    , FreeFormItems
    , from
    , getItems
    , size
    )

import Models.DiagramSettings as DiagramSettings
import Models.Item as Item exposing (Item, Items)
import Models.ItemSettings as ItemSettings
import Models.Size exposing (Size)


type FreeForm
    = FreeForm FreeFormItems


type alias FreeFormItems =
    List FreeFormItem


type FreeFormItem
    = Card Item
    | HorizontalLine Item
    | VerticalLine Item
    | Canvas Item
    | Text Item


getItems : FreeForm -> FreeFormItems
getItems (FreeForm items) =
    items


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
                            Item.withItemSettings
                                (Item.getItemSettings childItem
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


from : Items -> FreeForm
from items =
    FreeForm
        (items
            |> Item.map itemToFreeFormItem
            |> List.concat
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

        Canvas item_ ->
            item_

        Text item_ ->
            item_


size : DiagramSettings.Settings -> FreeForm -> Size
size settings freeForm =
    let
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

        freeFormWidth : Int
        freeFormWidth =
            List.map
                (\( w, _ ) ->
                    w
                )
                positionList
                |> List.maximum
                |> Maybe.withDefault 0

        freeFormHeight : Int
        freeFormHeight =
            List.map
                (\( _, h ) ->
                    h
                )
                positionList
                |> List.maximum
                |> Maybe.withDefault 0
    in
    ( freeFormWidth, freeFormHeight )
