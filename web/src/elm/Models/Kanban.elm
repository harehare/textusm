module Models.Kanban exposing (Card, Kanban, KanbanList, itemsToKanban)

import Models.Item as Item exposing (Item, Items)


type alias Name =
    String


type Kanban
    = Kanban (List KanbanList)


type KanbanList
    = KanbanList Name (List Card)


type Card
    = Card Name


itemsToKanban : Items -> Kanban
itemsToKanban items =
    Kanban (Item.map itemsToKanbanList items)


itemsToKanbanList : Item -> KanbanList
itemsToKanbanList item =
    KanbanList item.text (Item.map itemToCard (Item.unwrapChildren item.children))


itemToCard : Item -> Card
itemToCard item =
    Card item.text
