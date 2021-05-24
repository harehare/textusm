module Models.Views.UseCaseDiagram exposing (UseCaseDiagram(..), UseCaseItem(..), from)

import Data.Item as Item exposing (Item, Items)
import Set exposing (Set)


type alias Name =
    String


type UseCaseDiagram
    = UseCaseDiagram (List UseCaseItem)


type UseCaseItem
    = Actor Name (Set Name)
    | Subject Name (List UseCase)
    | UseCaseItem (List UseCase)


type UseCase
    = UseCase Name
    | Extend Name UseCase
    | Include Name UseCase


itemToUseCaseItem : Item -> UseCaseItem
itemToUseCaseItem item =
    let
        text =
            Item.getText item

        dropChar =
            String.dropLeft 1 >> String.dropRight 1
    in
    case ( String.left 1 <| text, String.right 1 <| text ) of
        ( "[", "]" ) ->
            Actor (dropChar text) <| Set.fromList (Item.map (\t -> Item.getText t) <| Item.getChildrenItems item)

        ( "(", ")" ) ->
            Subject (dropChar text) (Item.map itemToUseCase <| Item.getChildrenItems item)

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
