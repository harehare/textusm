module Models.Views.UseCaseDiagram exposing
    ( Actor(..)
    , Relation(..)
    , UseCase(..)
    , UseCaseDiagram(..)
    , UseCaseRelation
    , from
    , getRelationName
    , getRelations
    , relationCount
    )

import Data.Item as Item exposing (Item, Items)
import Dict exposing (Dict)
import Maybe.Extra as MaybeEx


type UseCaseDiagram
    = UseCaseDiagram (List Actor) UseCaseRelation


type UseCase
    = UseCase Item


type Actor
    = Actor Item (List UseCase)


type alias UseCaseRelation =
    Dict String (List Relation)


type Relation
    = Extend Item
    | Include Item


relationCount : Item -> UseCaseRelation -> Int
relationCount item relations =
    let
        childrens =
            Dict.get (Item.getText item) relations

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


getRelations : Item -> UseCaseRelation -> Maybe (List Relation)
getRelations item relation =
    Dict.get (String.trim <| Item.getText item) relation


getRelationName : Relation -> String
getRelationName r =
    Item.getText <|
        case r of
            Extend n ->
                n

            Include n ->
                n


itemToActor : Item -> Maybe Actor
itemToActor item =
    let
        originalText =
            Item.getText item
    in
    case ( String.left 1 originalText, String.right 1 originalText ) of
        ( "[", "]" ) ->
            Just <| Actor item <| (Item.map (\i -> UseCase <| i) <| Item.getChildrenItems item)

        _ ->
            Nothing


itemToUseCase : Item -> Maybe UseCaseRelation
itemToUseCase item =
    let
        originalText =
            Item.getText item

        name =
            originalText
                |> String.dropLeft 1
                |> String.dropRight 1
    in
    case ( String.left 1 originalText, String.right 1 originalText ) of
        ( "(", ")" ) ->
            Just <| Dict.fromList [ ( name, Item.map itemToRelation (Item.getChildrenItems item) ) ]

        _ ->
            Nothing


itemToRelation : Item -> Relation
itemToRelation item =
    let
        text =
            Item.getText item
    in
    case String.words <| String.trim <| text of
        [ "<", _ ] ->
            Extend item

        [ ">", _ ] ->
            Include item

        _ ->
            Extend item


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
