module Data.Item exposing (Children, Item, ItemType(..), Items, childrenFromItems, cons, empty, emptyChildren, filter, fromList, getAt, getBackgroundColor, getChildren, getChildrenCount, getColor, getHierarchyCount, getItemType, getLeafCount, getLineNo, getText, head, indexedMap, isEmpty, isImage, isMarkdown, length, map, new, splitAt, tail, toString, unwrap, unwrapChildren, withBackgroundColor, withChildren, withColor, withItemType, withLineNo, withText)

import Data.Color as Color exposing (Color)
import List.Extra as ListEx


type Children
    = Children Items


type Items
    = Items (List Item)


type Item
    = Item
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


new : Item
new =
    Item
        { lineNo = 0
        , text = ""
        , color = Nothing
        , backgroundColor = Nothing
        , itemType = Activities
        , children = emptyChildren
        }


withLineNo : Int -> Item -> Item
withLineNo lineNo (Item item) =
    Item { item | lineNo = lineNo }


withText : String -> Item -> Item
withText text (Item item) =
    let
        ( displayText, color, backgroundColor ) =
            if isImage text then
                ( text, Nothing, Nothing )

            else
                case String.split "," text of
                    [ t, c, b ] ->
                        ( t, Just c, Just b )

                    [ t, c ] ->
                        ( t, Just c, Nothing )

                    _ ->
                        ( text, Nothing, Nothing )
    in
    Item
        { item
            | text = displayText
            , color = Maybe.andThen (\c -> Just <| Color.fromString c) color
            , backgroundColor = Maybe.andThen (\c -> Just <| Color.fromString c) backgroundColor
        }


withColor : Maybe Color -> Item -> Item
withColor color (Item item) =
    Item { item | color = color }


withBackgroundColor : Maybe Color -> Item -> Item
withBackgroundColor color (Item item) =
    Item { item | backgroundColor = color }


withItemType : ItemType -> Item -> Item
withItemType itemType (Item item) =
    Item { item | itemType = itemType }


withChildren : Children -> Item -> Item
withChildren children (Item item) =
    Item { item | children = children }


getChildren : Item -> Children
getChildren (Item i) =
    i.children


getText : Item -> String
getText (Item i) =
    i.text


getItemType : Item -> ItemType
getItemType (Item i) =
    i.itemType


getColor : Item -> Maybe Color
getColor (Item i) =
    i.color


getBackgroundColor : Item -> Maybe Color
getBackgroundColor (Item i) =
    i.backgroundColor


getLineNo : Item -> Int
getLineNo (Item i) =
    i.lineNo


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


unwrapChildren : Children -> Items
unwrapChildren (Children (Items items)) =
    Items (items |> List.filter (\(Item i) -> i.itemType /= Comments))


getChildrenCount : Item -> Int
getChildrenCount (Item item) =
    childrenCount <| unwrapChildren item.children


childrenCount : Items -> Int
childrenCount (Items items) =
    if List.isEmpty items then
        0

    else
        List.length items + (items |> List.map (\(Item i) -> childrenCount <| unwrapChildren i.children) |> List.sum) + 1


getHierarchyCount : Item -> Int
getHierarchyCount (Item item) =
    unwrapChildren item.children
        |> hierarchyCount
        |> List.length


hierarchyCount : Items -> List Int
hierarchyCount (Items items) =
    if List.isEmpty items then
        []

    else
        1 :: List.concatMap (\(Item i) -> hierarchyCount <| unwrapChildren i.children) items


getLeafCount : Item -> Int
getLeafCount (Item item) =
    leafCount <| unwrapChildren item.children


leafCount : Items -> Int
leafCount (Items items) =
    if List.isEmpty items then
        1

    else
        items |> List.map (\(Item i) -> leafCount <| unwrapChildren i.children) |> List.sum


toString : Items -> String
toString =
    let
        itemsToString : Int -> Items -> String
        itemsToString hierarcy items =
            let
                itemToString : Item -> Int -> String
                itemToString (Item i) hi =
                    String.repeat hi "    " ++ i.text
            in
            items
                |> map
                    (\(Item item) ->
                        case item.children of
                            Children c ->
                                itemToString (Item item) hierarcy ++ "\n" ++ itemsToString (hierarcy + 1) c
                    )
                |> String.join "\n"
    in
    itemsToString 0
