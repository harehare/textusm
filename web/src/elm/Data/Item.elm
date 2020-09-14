module Data.Item exposing (Item, ItemType(..), Items(..), childrenFromItems, cons, create, empty, emptyChildren, emptyItem, filter, fromList, getAt, getChildrenCount, getHierarchyCount, getLeafCount, head, indexedMap, isEmpty, isImage, isMarkdown, length, map, splitAt, tail, toString, unwrap, unwrapChildren)

import Data.Color as Color exposing (Color)
import List.Extra as ListEx


type Children
    = Children Items


type Items
    = Items (List Item)


type alias Item =
    { lineNo : Int
    , text : String
    , color : Maybe Color
    , backgroundColor : Maybe Color
    , itemType : ItemType
    , children : Children
    }


type ItemType
    = Activities
    | Tasks
    | Stories Int
    | Comments


create : Int -> String -> ItemType -> Children -> Item
create lineNo text itemType children =
    let
        ( displayText, color, backgroundColor ) =
            if isMarkdown text then
                case String.split "," text of
                    [ t, c, b ] ->
                        ( t, Just c, Just b )

                    [ t, c ] ->
                        ( t, Just c, Nothing )

                    _ ->
                        ( text, Nothing, Nothing )

            else
                ( text, Nothing, Nothing )
    in
    { lineNo = lineNo
    , text = displayText
    , color = Maybe.andThen (\c -> Just <| Color.fromString c) color
    , backgroundColor = Maybe.andThen (\c -> Just <| Color.fromString c) backgroundColor
    , itemType = itemType
    , children = children
    }


isImage : String -> Bool
isImage text =
    String.trim text |> String.toLower |> String.startsWith "data:image/"


isMarkdown : String -> Bool
isMarkdown text =
    String.trim text |> String.toLower |> String.startsWith "md:"


getAt : Int -> Items -> Maybe Item
getAt i (Items items) =
    ListEx.getAt i items


head : Items -> Maybe Item
head (Items items) =
    List.head items


tail : Items -> Maybe Items
tail (Items items) =
    List.tail items
        |> Maybe.map (\i -> Items i)


map : (Item -> a) -> Items -> List a
map f (Items items) =
    List.map f items


filter : (Item -> Bool) -> Items -> Items
filter f (Items items) =
    Items (List.filter f items)


empty : Items
empty =
    Items []


cons : Item -> Items -> Items
cons item (Items items) =
    Items (item :: items)


indexedMap : (Int -> Item -> b) -> Items -> List b
indexedMap f (Items items) =
    List.indexedMap f items


length : Items -> Int
length (Items items) =
    List.length items


isEmpty : Items -> Bool
isEmpty items =
    length items == 0


unwrap : Items -> List Item
unwrap (Items items) =
    items


splitAt : Int -> Items -> ( Items, Items )
splitAt i (Items items) =
    let
        ( left, right ) =
            ListEx.splitAt i items
    in
    ( Items left, Items right )


childrenFromItems : Items -> Children
childrenFromItems (Items items) =
    Children (Items items)


fromList : List Item -> Items
fromList items =
    Items items


emptyChildren : Children
emptyChildren =
    Children empty


emptyItem : Item
emptyItem =
    { lineNo = 0
    , text = ""
    , color = Nothing
    , backgroundColor = Nothing
    , itemType = Activities
    , children = emptyChildren
    }


unwrapChildren : Children -> Items
unwrapChildren (Children (Items items)) =
    Items (items |> List.filter (\i -> i.itemType /= Comments))


getChildrenCount : Item -> Int
getChildrenCount item =
    childrenCount <| unwrapChildren item.children


childrenCount : Items -> Int
childrenCount (Items items) =
    if List.isEmpty items then
        0

    else
        List.length items + (items |> List.map (\i -> childrenCount <| unwrapChildren i.children) |> List.sum) + 1


getHierarchyCount : Item -> Int
getHierarchyCount item =
    unwrapChildren item.children
        |> hierarchyCount
        |> List.length


hierarchyCount : Items -> List Int
hierarchyCount (Items items) =
    if List.isEmpty items then
        []

    else
        1 :: List.concatMap (\i -> hierarchyCount <| unwrapChildren i.children) items


getLeafCount : Item -> Int
getLeafCount item =
    leafCount <| unwrapChildren item.children


leafCount : Items -> Int
leafCount (Items items) =
    if List.isEmpty items then
        1

    else
        items |> List.map (\i -> leafCount <| unwrapChildren i.children) |> List.sum


toString : Items -> String
toString =
    let
        itemsToString : Int -> Items -> String
        itemsToString hierarcy items =
            let
                itemToString : Item -> Int -> String
                itemToString i hi =
                    String.repeat hi "    " ++ i.text
            in
            items
                |> map
                    (\item ->
                        case item.children of
                            Children c ->
                                itemToString item hierarcy ++ "\n" ++ itemsToString (hierarcy + 1) c
                    )
                |> String.join "\n"
    in
    itemsToString 0
