module Diagram.SiteMap.Types exposing (size)

import Constants
import Diagram.Types.CardSize as CardSize
import Diagram.Types.Settings as DiagramSettings
import Types.Item as Item exposing (Items)
import Types.Size exposing (Size)


size : DiagramSettings.Settings -> Items -> Int -> Size
size settings siteMapitems hierarchy =
    let
        items : Items
        items =
            siteMapitems
                |> Item.head
                |> Maybe.withDefault Item.new
                |> Item.getChildren
                |> Item.unwrapChildren

        maxChildrenCount : Int
        maxChildrenCount =
            items
                |> Item.map
                    (\i ->
                        if Item.isEmpty (Item.unwrapChildren <| Item.getChildren i) then
                            0

                        else
                            Item.getChildrenCount i
                    )
                |> List.maximum
                |> Maybe.withDefault 0

        svgHeight : Int
        svgHeight =
            (CardSize.toInt settings.size.height
                + Constants.itemSpan
            )
                * (maxChildrenCount
                    + 2
                  )

        svgWidth : Int
        svgWidth =
            (CardSize.toInt settings.size.width
                + Constants.itemSpan
            )
                * Item.length items
                + Constants.itemSpan
                * hierarchy
    in
    ( svgWidth + Constants.itemSpan, svgHeight + Constants.itemSpan )
