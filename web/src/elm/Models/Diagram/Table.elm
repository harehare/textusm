module Models.Diagram.Table exposing (Header(..), Row(..), Table(..), from, toString)

import Types.Item as Item exposing (Item, ItemType(..), Items)


type Table
    = Table Header (List Row)


type Header
    = Header Item


type Row
    = Row Item


from : Items -> Table
from items =
    Table
        (Header
            (items
                |> Item.head
                |> Maybe.withDefault Item.new
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
                ++ ((Item.getText headerItem
                        :: (Item.getChildren headerItem
                                |> Item.unwrapChildren
                                |> Item.map (\i -> String.trim <| Item.getText i)
                           )
                    )
                        |> String.join "|"
                   )
                ++ "|"

        section =
            "|"
                ++ ((" " ++ String.repeat (Item.getText headerItem |> String.trim |> String.length) "-" ++ " ")
                        :: (Item.getChildren headerItem
                                |> Item.unwrapChildren
                                |> Item.map
                                    (\item ->
                                        " " ++ String.repeat (Item.getText item |> String.trim |> String.length) "-" ++ " "
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
                            ++ (Item.getText item
                                    :: (item
                                            |> Item.getChildren
                                            |> Item.unwrapChildren
                                            |> Item.map (\i -> String.trim <| Item.getText i)
                                       )
                                    |> String.join "|"
                               )
                            ++ "|"
                    )
                |> String.join "\n"
    in
    String.join "\n" [ header, section, row ]
