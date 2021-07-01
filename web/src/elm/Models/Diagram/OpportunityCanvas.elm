module Models.Diagram.OpportunityCanvas exposing (OpportunityCanvas, OpportunityCanvasItem(..), from)

import Types.Item as Item exposing (Item, Items)


type alias OpportunityCanvas =
    { usersAndCustomers : OpportunityCanvasItem
    , problems : OpportunityCanvasItem
    , solutionsToday : OpportunityCanvasItem
    , solutionIdeas : OpportunityCanvasItem
    , howWillUsersUseSolution : OpportunityCanvasItem
    , adoptionStrategy : OpportunityCanvasItem
    , userMetrics : OpportunityCanvasItem
    , businessChallenges : OpportunityCanvasItem
    , budget : OpportunityCanvasItem
    , businessBenefitsAndMetrics : OpportunityCanvasItem
    }


type OpportunityCanvasItem
    = OpportunityCanvasItem Item


from : Items -> OpportunityCanvas
from items =
    OpportunityCanvas (items |> Item.getAt 2 |> Maybe.withDefault Item.new |> OpportunityCanvasItem)
        (items |> Item.getAt 0 |> Maybe.withDefault Item.new |> OpportunityCanvasItem)
        (items |> Item.getAt 3 |> Maybe.withDefault Item.new |> OpportunityCanvasItem)
        (items |> Item.getAt 1 |> Maybe.withDefault Item.new |> OpportunityCanvasItem)
        (items |> Item.getAt 5 |> Maybe.withDefault Item.new |> OpportunityCanvasItem)
        (items |> Item.getAt 7 |> Maybe.withDefault Item.new |> OpportunityCanvasItem)
        (items |> Item.getAt 6 |> Maybe.withDefault Item.new |> OpportunityCanvasItem)
        (items |> Item.getAt 4 |> Maybe.withDefault Item.new |> OpportunityCanvasItem)
        (items |> Item.getAt 9 |> Maybe.withDefault Item.new |> OpportunityCanvasItem)
        (items |> Item.getAt 8 |> Maybe.withDefault Item.new |> OpportunityCanvasItem)
