module Models.Views.Table exposing (Header(..), Row(..), Table(..), fromItems, toString)

import Data.Item as Item exposing (Item, ItemType(..), Items)


type Table
    = Table Header (List Row)


type Header
    = Header Item


type Row
    = Row Item


fromItems : Items -> Table
fromItems items =
    Table
        (Header
            (items
                |> Item.head
                |> Maybe.withDefault Item.emptyItem
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

        (Header headerItem) =
            h

        header =
            "|"
                ++ ((headerItem.text
                        :: (headerItem.children
                                |> Item.unwrapChildren
                                |> Item.map (\i -> String.trim i.text)
                           )
                    )
                        |> String.join "|"
                   )
                ++ "|"

        section =
            "|"
                ++ ((" " ++ String.repeat (String.trim headerItem.text |> String.length) "-" ++ " ")
                        :: (headerItem.children
                                |> Item.unwrapChildren
                                |> Item.map
                                    (\item ->
                                        " " ++ String.repeat (String.trim item.text |> String.length) "-" ++ " "
                                    )
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
