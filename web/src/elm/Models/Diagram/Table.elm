module Models.Diagram.Table exposing
    ( Header(..)
    , Row(..)
    , Table(..)
    , from
    , size
    , toString
    )

import Constants
import Models.DiagramSettings as DiagramSettings
import Models.Item as Item exposing (Item, Items)
import Models.Size exposing (Size)


type Header
    = Header Item


type Row
    = Row Item


type Table
    = Table Header (List Row)


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


size : DiagramSettings.Settings -> Items -> Size
size settings items =
    ( settings.size.width * ((items |> Item.head |> Maybe.withDefault Item.new |> Item.getChildren |> Item.unwrapChildren |> Item.length) + 1)
    , settings.size.height * Item.length items + Constants.itemMargin
    )


toString : Table -> String
toString table =
    let
        (Table h rows) =
            table

        header : String
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

        (Header headerItem) =
            h

        row : String
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

        section : String
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
    in
    String.join "\n" [ header, section, row ]
