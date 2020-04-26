module Models.Views.Kanban exposing (Card(..), Kanban(..), KanbanList(..), fromItems, getCardCount, getListCount)

import Data.Item as Item exposing (Item, Items)


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


fromItems : Items -> Kanban
fromItems items =
    Kanban (Item.map fromItemsList items)


fromItemsList : Item -> KanbanList
fromItemsList item =
    KanbanList item.text (Item.map itemToCard (Item.unwrapChildren item.children))


itemToCard : Item -> Card
itemToCard item =
    Card item
