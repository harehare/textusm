module Diagram.Kanban.Types exposing
    ( Card(..)
    , Kanban(..)
    , KanbanList(..)
    , Name
    , from
    , getCardCount
    , size
    )

import Constants
import Diagram.Types.CardSize as CardSize
import Diagram.Types.Settings as DiagramSettings
import Types.Item as Item exposing (Item, Items)
import Types.Size exposing (Size)


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
    ( getListCount kanban * (CardSize.toInt settings.size.width + Constants.itemMargin * 3)
    , getCardCount kanban * (CardSize.toInt settings.size.height + Constants.itemMargin) + Constants.itemMargin * 2
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
