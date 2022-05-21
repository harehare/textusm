module Models.Diagram.Kanban exposing
    ( Card(..)
    , Kanban(..)
    , KanbanList(..)
    , Name
    , from
    , getCardCount
    , size
    )

import Constants
import Models.DiagramSettings as DiagramSettings
import Models.Item as Item exposing (Item, Items)
import Models.Size exposing (Size)


type Card
    = Card Item


type Kanban
    = Kanban (List KanbanList)


type KanbanList
    = KanbanList Name (List Card)


type alias Name =
    String


from : Items -> Kanban
from items =
    Kanban (Item.map fromItemsList items)


getCardCount : Kanban -> Int
getCardCount (Kanban lists) =
    lists
        |> List.map (\(KanbanList _ cards) -> List.length cards)
        |> List.maximum
        |> Maybe.withDefault 0


size : DiagramSettings.Settings -> Kanban -> Size
size settings kanban =
    ( getListCount kanban * (settings.size.width + Constants.itemMargin * 3)
    , getCardCount kanban * (settings.size.height + Constants.itemMargin) + Constants.itemMargin * 2
    )


fromItemsList : Item -> KanbanList
fromItemsList item =
    KanbanList (Item.getText item) (Item.map itemToCard (Item.unwrapChildren <| Item.getChildren item))


getListCount : Kanban -> Int
getListCount (Kanban lists) =
    List.length lists


itemToCard : Item -> Card
itemToCard item =
    Card item
