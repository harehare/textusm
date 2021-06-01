module Models.Views.UseCaseDiagram exposing
    ( Actor(..)
    , Relation(..)
    , UseCase(..)
    , UseCaseDiagram(..)
    , UseCaseRelation
    , from
    , relationCount
    )

import Data.Item as Item exposing (Item, Items)
import Dict exposing (Dict)
import Maybe.Extra as MaybeEx


type alias Name =
    String


type UseCaseDiagram
    = UseCaseDiagram (List Actor) UseCaseRelation


type UseCase
    = UseCase Name


type Actor
    = Actor Item (List UseCase)


type alias UseCaseRelation =
    Dict String (List Relation)


type Relation
    = Extend Name
    | Include Name


relationCount : String -> UseCaseRelation -> Int
relationCount name relations =
    let
        childrens =
            Dict.get name relations

        relationName relation =
            case relation of
                Extend e ->
                    e

                Include i ->
                    i
    in
    case childrens of
        Just c ->
            List.length c + (List.map (\v -> relationCount (relationName v) relations) c |> List.sum)

        Nothing ->
            1


itemToActor : Item -> Maybe Actor
itemToActor item =
    let
        text =
            Item.getText item
    in
    case ( String.left 1 text, String.right 1 text ) of
        ( "[", "]" ) ->
            Just <| Actor item <| (Item.map (\i -> UseCase <| Item.getText i) <| Item.getChildrenItems item)

        _ ->
            Nothing


itemToUseCase : Item -> Maybe UseCaseRelation
itemToUseCase item =
    let
        text =
            Item.getText item
    in
    case ( String.left 1 text, String.right 1 text ) of
        ( "(", ")" ) ->
            Just <| Dict.fromList [ ( text, Item.map itemToRelation (Item.getChildrenItems item) ) ]

        _ ->
            Nothing


itemToRelation : Item -> Relation
itemToRelation item =
    let
        text =
            Item.getText item
    in
    case String.words <| String.trim <| text of
        [ "<", e ] ->
            Extend e

        [ ">", i ] ->
            Include i

        _ ->
            Extend text


emptyActor : Actor
emptyActor =
    Actor Item.new []


emptyUseCaseRelation : UseCaseRelation
emptyUseCaseRelation =
    Dict.empty


from : Items -> UseCaseDiagram
from items =
    UseCaseDiagram
        (Item.map itemToActor items
            |> List.filter MaybeEx.isJust
            |> List.map (Maybe.withDefault emptyActor)
        )
        (Item.map itemToUseCase items
            |> List.filter MaybeEx.isJust
            |> List.map (Maybe.withDefault emptyUseCaseRelation)
            |> List.foldl Dict.union Dict.empty
        )
