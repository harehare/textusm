module Models.Item exposing (Children, Item, ItemType(..), emptyChildren, emptyItem, fromItems, getChildrenCount, getHierarchyCount, getLeafCount, toString, unwrapChildren)


type Children
    = Children (List Item)


type alias Item =
    { lineNo : Int
    , text : String
    , itemType : ItemType
    , children : Children
    }


type ItemType
    = Activities
    | Tasks
    | Stories Int
    | Comments


fromItems : List Item -> Children
fromItems items =
    Children items


emptyChildren : Children
emptyChildren =
    Children []


emptyItem : Item
emptyItem =
    { lineNo = 0
    , text = ""
    , itemType = Activities
    , children = emptyChildren
    }


unwrapChildren : Children -> List Item
unwrapChildren (Children items) =
    items |> List.filter (\i -> i.itemType /= Comments)


getChildrenCount : Item -> Int
getChildrenCount item =
    childrenCount <| unwrapChildren item.children


childrenCount : List Item -> Int
childrenCount ii =
    if List.isEmpty ii then
        0

    else
        List.length ii + (ii |> List.map (\i -> childrenCount <| unwrapChildren i.children) |> List.sum) + 1


getHierarchyCount : Item -> Int
getHierarchyCount item =
    unwrapChildren item.children
        |> hierarchyCount
        |> List.length


hierarchyCount : List Item -> List Int
hierarchyCount ii =
    if List.isEmpty ii then
        []

    else
        1 :: List.concatMap (\i -> hierarchyCount <| unwrapChildren i.children) ii


getLeafCount : Item -> Int
getLeafCount item =
    leafCount <| unwrapChildren item.children


leafCount : List Item -> Int
leafCount ii =
    if List.isEmpty ii then
        1

    else
        ii |> List.map (\i -> leafCount <| unwrapChildren i.children) |> List.sum


toString : List Item -> String
toString =
    let
        itemsToString : Int -> List Item -> String
        itemsToString hierarcy items =
            let
                itemToString : Item -> Int -> String
                itemToString i hi =
                    String.repeat hi "    " ++ i.text
            in
            items
                |> List.map
                    (\item ->
                        case item.children of
                            Children [] ->
                                itemToString item hierarcy

                            Children c ->
                                itemToString item hierarcy ++ "\n" ++ itemsToString (hierarcy + 1) c
                    )
                |> String.join "\n"
    in
    itemsToString 0
