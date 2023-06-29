module Models.Diagram.UseCaseDiagram exposing
    ( Actor(..)
    , Relation(..)
    , UseCase(..)
    , UseCaseDiagram(..)
    , UseCaseRelation
    , from
    , getName
    , getRelationItem
    , getRelationName
    , getRelations
    , relationCount
    , size
    )

import Dict exposing (Dict)
import List.Extra as ListEx
import Maybe.Extra as MaybeEx
import Models.Item as Item exposing (Item, Items)
import Models.Size exposing (Size)


type Actor
    = Actor Item (List UseCase)


type Relation
    = Extend Item
    | Include Item


type UseCase
    = UseCase Item


type UseCaseDiagram
    = UseCaseDiagram (List Actor) UseCaseRelation


type alias UseCaseRelation =
    Dict String (List Relation)


from : Items -> UseCaseDiagram
from items =
    UseCaseDiagram
        (Item.map itemToActor items
            |> List.filter MaybeEx.isJust
            |> List.map (Maybe.withDefault emptyActor)
        )
        (Item.map itemToUseCase items
            |> List.filterMap identity
            |> List.foldl Dict.union Dict.empty
        )


getName : Item -> String
getName item =
    let
        text : String
        text =
            String.trim <| Item.getText item

        trimText : String -> String
        trimText v =
            v
                |> String.dropLeft 1
                |> String.trim
    in
    case String.left 1 <| text of
        "(" ->
            trimText text |> String.dropRight 1

        "<" ->
            trimText text

        ">" ->
            trimText text

        "[" ->
            trimText text |> String.dropRight 1

        _ ->
            text


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


getRelations : Item -> UseCaseRelation -> Maybe (List Relation)
getRelations item relation =
    Dict.get (getName item) relation


relationCount : Item -> UseCaseRelation -> Int
relationCount item relations =
    let
        childrens : Maybe (List Relation)
        childrens =
            Dict.get (Item.getText item |> String.trim) relations

        relationName : Relation -> Item
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


size : UseCaseDiagram -> Size
size (UseCaseDiagram actors relations) =
    let
        count : Int
        count =
            allRelationCount useCases relations

        h : Int
        h =
            hierarchy useCases relations

        useCases : List Item
        useCases =
            List.concatMap (\(Actor _ a) -> List.map (\(UseCase u) -> u) a) actors
                |> ListEx.uniqueBy Item.getText
    in
    ( (h + 1) * 320, count * 70 )


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


emptyActor : Actor
emptyActor =
    Actor Item.new []


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


itemToActor : Item -> Maybe Actor
itemToActor item =
    let
        originalText : String
        originalText =
            Item.getText item
                |> String.trim
    in
    case ( String.left 1 originalText, String.right 1 originalText ) of
        ( "[", "]" ) ->
            Just <| Actor item <| (Item.map (\i -> UseCase <| i) <| Item.getChildrenItems item)

        _ ->
            Nothing


itemToRelation : Item -> Relation
itemToRelation item =
    let
        text : String
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


itemToUseCase : Item -> Maybe UseCaseRelation
itemToUseCase item =
    let
        originalText : String
        originalText =
            Item.getText item
                |> String.trim
    in
    case ( String.left 1 originalText, String.right 1 originalText ) of
        ( "(", ")" ) ->
            let
                name : String
                name =
                    originalText
                        |> String.dropLeft 1
                        |> String.dropRight 1
            in
            Just <| Dict.fromList [ ( name, Item.map itemToRelation (Item.getChildrenItems item) ) ]

        _ ->
            Nothing
