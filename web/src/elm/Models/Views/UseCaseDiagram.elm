module Models.Views.UseCaseDiagram exposing (UseCase(..), UseCaseDiagram(..), UseCaseItem(..), from)

import Data.Item as Item exposing (Item, Items)
import Set exposing (Set)


type alias Name =
    String


type UseCaseDiagram
    = UseCaseDiagram (List UseCaseItem)


type UseCaseItem
    = Actor Name (Set Name)
    | UseCaseItem (List UseCase)


type UseCase
    = UseCase Name
    | Extend Name Name
    | Include Name Name


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
            UseCaseItem (Item.map itemToUseCase <| Item.getChildrenItems item)

        _ ->
            UseCaseItem []


itemToUseCase : Item -> UseCase
itemToUseCase item =
    case String.words <| Item.getText item of
        [ u, "<", e ] ->
            Extend e u

        [ u, ">", i ] ->
            Include i u

        _ ->
            UseCase <| Item.getText item


from : Items -> UseCaseDiagram
from items =
    UseCaseDiagram <| Item.map itemToUseCaseItem items
