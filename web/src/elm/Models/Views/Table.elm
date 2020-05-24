module Models.Views.Table exposing (Header(..), Row(..), Table(..), fromItems, toString)

import Data.Item as Item exposing (Item, ItemType(..), Items)


type Table
    = Table Header (List Row)


type Header
    = Header Items


type Row
    = Row Item


fromItems : Items -> Table
fromItems items =
    Table
        (Header
            (items
                |> Item.head
                |> Maybe.withDefault Item.emptyItem
                |> .children
                |> Item.unwrapChildren
            )
        )
        (items
            |> Item.tail
            |> Maybe.withDefault Item.empty
            |> Item.map Row
        )


toString : Table -> String
toString table =
    let
        (Table h rows) =
            table

        (Header headerItems) =
            h

        header =
            "|"
                ++ (headerItems
                        |> Item.map (\i -> String.trim i.text)
                        |> String.join "|"
                   )
                ++ "|"

        section =
            "|"
                ++ (Item.cons
                        (Item 0 "dummy" Activities Item.emptyChildren)
                        headerItems
                        |> Item.map
                            (\item ->
                                " " ++ String.repeat (String.trim item.text |> String.length) "-" ++ " "
                            )
                        |> String.join "|"
                   )
                ++ "|"

        row =
            rows
                |> List.map
                    (\(Row item) ->
                        "|"
                            ++ (item.text
                                    :: (item
                                            |> .children
                                            |> Item.unwrapChildren
                                            |> Item.map (\i -> String.trim i.text)
                                       )
                                    |> String.join "|"
                               )
                            ++ "|"
                    )
                |> String.join "\n"
    in
    String.join "\n" [ header, section, row ]
