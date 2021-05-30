module Models.Views.UseCaseDiagram exposing (Actor(..), Relation(..), UseCase(..), UseCaseDiagram(..), from)

import Data.Item as Item exposing (Item, Items)


type alias Name =
    String


type UseCaseDiagram
    = UseCaseDiagram (List Actor)


type Actor
    = Actor Item (List UseCase)


type UseCase
    = UseCase Item Relation


type Relation
    = Extend Name
    | Include Name
    | None


itemToActor : Item -> Actor
itemToActor item =
    Actor item <| (Item.map (\i -> itemToUseCase i) <| Item.getChildrenItems item)


itemToUseCase : Item -> UseCase
itemToUseCase item =
    let
        text =
            Item.getText item
    in
    case String.words <| String.trim <| text of
        [ _, "<", e ] ->
            UseCase item <| Extend e

        [ _, ">", i ] ->
            UseCase item <| Include i

        _ ->
            UseCase item None


from : Items -> UseCaseDiagram
from items =
    UseCaseDiagram <| Item.map itemToActor items
