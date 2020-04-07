module Models.Kanban exposing (Card(..), Kanban(..), KanbanList(..), getCardCount, getListCount, itemsToKanban)

import Models.Item as Item exposing (Item, Items)


type alias Name =
    String


type Kanban
    = Kanban (List KanbanList)


type KanbanList
    = KanbanList Name (List Card)


type Card
    = Card Item


getListCount : Kanban -> Int
getListCount (Kanban lists) =
    List.length lists


getCardCount : Kanban -> Int
getCardCount (Kanban lists) =
    lists
        |> List.map (\(KanbanList _ cards) -> List.length cards)
        |> List.maximum
        |> Maybe.withDefault 0


itemsToKanban : Items -> Kanban
itemsToKanban items =
    Kanban (Item.map itemsToKanbanList items)


itemsToKanbanList : Item -> KanbanList
itemsToKanbanList item =
    KanbanList item.text (Item.map itemToCard (Item.unwrapChildren item.children))


itemToCard : Item -> Card
itemToCard item =
    Card item
