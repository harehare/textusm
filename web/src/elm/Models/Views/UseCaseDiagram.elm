module Models.Views.UseCaseDiagram exposing
    ( Actor(..)
    , Relation(..)
    , UseCase(..)
    , UseCaseDiagram(..)
    , UseCaseRelation
    , allRelationCount
    , from
    , getName
    , getRelationItem
    , getRelationName
    , getRelations
    , hierarchy
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


getName : Item -> String
getName item =
    let
        text =
            String.trim <| Item.getText item

        trimText v =
            v
                |> String.dropLeft 1
                |> String.trim
    in
    case String.left 1 <| text of
        "[" ->
            trimText text |> String.dropRight 1

        "(" ->
            trimText text |> String.dropRight 1

        "<" ->
            trimText text

        ">" ->
            trimText text

        _ ->
            text


relationCount : Item -> UseCaseRelation -> Int
relationCount item relations =
    let
        childrens =
            Dict.get (Item.getText item |> String.trim) relations

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
            0


getRelations : Item -> UseCaseRelation -> Maybe (List Relation)
getRelations item relation =
    Dict.get (getName item) relation


getRelationItem : Relation -> Item
getRelationItem r =
    case r of
        Extend n ->
            n

        Include n ->
            n


getRelationName : Relation -> String
getRelationName r =
    getName <|
        getRelationItem r


itemToActor : Item -> Maybe Actor
itemToActor item =
    let
        originalText =
            Item.getText item
                |> String.trim
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
                |> String.trim

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
    case String.left 1 <| String.trim <| text of
        "<" ->
            Extend item

        ">" ->
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


allRelationCount : List Item -> UseCaseRelation -> Int
allRelationCount items relations =
    List.map
        (\i ->
            case getRelations i relations of
                Just r ->
                    List.length r + allRelationCount (List.map getRelationItem r) relations

                Nothing ->
                    1
        )
        items
        |> List.sum


hierarchy : List Item -> UseCaseRelation -> Int
hierarchy items relations =
    hierarchyHelper 1 items relations


hierarchyHelper : Int -> List Item -> UseCaseRelation -> Int
hierarchyHelper h items relations =
    case items of
        x :: [] ->
            case getRelations x relations of
                Just r ->
                    hierarchyHelper (h + 1) (List.map getRelationItem r) relations

                Nothing ->
                    h

        x :: xs ->
            max
                (case getRelations x relations of
                    Just r ->
                        hierarchyHelper (h + 1) (List.map getRelationItem r) relations

                    Nothing ->
                        h
                )
            <|
                hierarchyHelper h xs relations

        _ ->
            h
