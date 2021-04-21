module Models.Views.UseCaseDiagram exposing (UseCaseItem, from)

import Data.Item as Item exposing (Item, Items)


type alias Name =
    String


type UseCaseDiagram
    = UseCaseDiagram (List UseCaseItem)


type UseCaseItem
    = Actor (List UseCase)
    | Subject Name (List UseCase)
    | UseCaseItem (List UseCase)


type UseCase
    = UseCase Name
    | Extend Name UseCase
    | Include Name UseCase


itemToUseCaseItem : Item -> UseCaseItem
itemToUseCaseItem item =
    case ( String.left 1 <| Item.getText item, String.right 1 <| Item.getText item ) of
        ( "[", "]" ) ->
            Actor <| Item.map (\t -> UseCase <| Item.getText t) <| Item.getChildrenItems item

        ( "(", ")" ) ->
            Subject (Item.getText item) (Item.map itemToUseCase <| Item.getChildrenItems item)

        _ ->
            UseCaseItem (Item.map itemToUseCase <| Item.getChildrenItems item)


itemToUseCase : Item -> UseCase
itemToUseCase item =
    case String.words <| Item.getText item of
        [ u, "<", e ] ->
            Extend e <| UseCase u

        [ u, ">", i ] ->
            Include i <| UseCase u

        _ ->
            UseCase <| Item.getText item


from : Items -> UseCaseDiagram
from items =
    UseCaseDiagram <| Item.map itemToUseCaseItem items
