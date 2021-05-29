module Models.Views.UseCaseDiagram exposing (UseCase(..), UseCaseDiagram(..), from)

import Data.Item as Item exposing (Item, Items)


type alias Name =
    String


type UseCaseDiagram
    = UseCaseDiagram (List Actor)


type Actor
    = Actor Name (List UseCase)


type UseCase
    = UseCase Name
    | Extend Name UseCase
    | Include Name UseCase


itemToActor : Item -> Actor
itemToActor item =
    let
        text =
            Item.getText item
    in
    Actor text <| (Item.map (\i -> itemToUseCase i) <| Item.getChildrenItems item)


itemToUseCase : Item -> UseCase
itemToUseCase item =
    case String.words <| String.trim <| Item.getText item of
        [ u, "<", e ] ->
            Extend e <| UseCase u

        [ u, ">", i ] ->
            Include i <| UseCase u

        _ ->
            UseCase <| Item.getText item


from : Items -> UseCaseDiagram
from items =
    UseCaseDiagram <| Item.map itemToActor items
