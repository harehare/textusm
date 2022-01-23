module Models.Diagram.SiteMap exposing (size)

import Constants
import Models.DiagramSettings as DiagramSettings
import Models.Item as Item exposing (Items)
import Models.Size exposing (Size)


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

        svgWidth : Int
        svgWidth =
            (settings.size.width
                + Constants.itemSpan
            )
                * Item.length items
                + Constants.itemSpan
                * hierarchy

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
            (settings.size.height
                + Constants.itemSpan
            )
                * (maxChildrenCount
                    + 2
                  )
    in
    ( svgWidth + Constants.itemSpan, svgHeight + Constants.itemSpan )
