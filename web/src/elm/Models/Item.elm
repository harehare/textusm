module Models.Item exposing (Children, Item, ItemType(..), empty, emptyItem, fromItems, toString, unwrapChildren)


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


empty : Children
empty =
    Children []


emptyItem : Item
emptyItem =
    { lineNo = 0
    , text = ""
    , itemType = Activities
    , children = empty
    }


unwrapChildren : Children -> List Item
unwrapChildren (Children items) =
    items


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
