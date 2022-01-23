module Models.Diagram.BusinessModelCanvas exposing (BusinessModelCanvas, BusinessModelCanvasItem(..), from, size)

import Constants
import Models.DiagramSettings as DiagramSettings
import Models.Item as Item exposing (Item, Items)
import Models.Size exposing (Size)
import Utils.Diagram as Utils


type alias BusinessModelCanvas =
    { keyPartners : BusinessModelCanvasItem
    , keyActivities : BusinessModelCanvasItem
    , keyResources : BusinessModelCanvasItem
    , valuePropotion : BusinessModelCanvasItem
    , customerRelationships : BusinessModelCanvasItem
    , channels : BusinessModelCanvasItem
    , customerSegments : BusinessModelCanvasItem
    , costStructure : BusinessModelCanvasItem
    , revenueStreams : BusinessModelCanvasItem
    }


type BusinessModelCanvasItem
    = BusinessModelCanvasItem Item


from : Items -> BusinessModelCanvas
from items =
    BusinessModelCanvas (items |> Item.getAt 0 |> Maybe.withDefault Item.new |> BusinessModelCanvasItem)
        (items |> Item.getAt 3 |> Maybe.withDefault Item.new |> BusinessModelCanvasItem)
        (items |> Item.getAt 7 |> Maybe.withDefault Item.new |> BusinessModelCanvasItem)
        (items |> Item.getAt 2 |> Maybe.withDefault Item.new |> BusinessModelCanvasItem)
        (items |> Item.getAt 8 |> Maybe.withDefault Item.new |> BusinessModelCanvasItem)
        (items |> Item.getAt 4 |> Maybe.withDefault Item.new |> BusinessModelCanvasItem)
        (items |> Item.getAt 1 |> Maybe.withDefault Item.new |> BusinessModelCanvasItem)
        (items |> Item.getAt 6 |> Maybe.withDefault Item.new |> BusinessModelCanvasItem)
        (items |> Item.getAt 5 |> Maybe.withDefault Item.new |> BusinessModelCanvasItem)


size : DiagramSettings.Settings -> Items -> Size
size settings items =
    ( Constants.itemWidth * 5 + 20, Basics.max Constants.itemHeight (Utils.getCanvasHeight settings items) * 3 + 50 )
