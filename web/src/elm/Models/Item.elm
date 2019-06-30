module Models.Item exposing (Children, Item, ItemType(..), fromItems, toString, unwrapChildren)


type Children
    = Children (List Item)


type alias Item =
    { lineNo : Int
    , text : String
    , comment : Maybe String
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
                    case i.comment of
                        Just c ->
                            String.repeat hi "    " ++ i.text ++ ": " ++ c

                        Nothing ->
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
