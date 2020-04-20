module Models.Views.CustomerJourneyMap exposing (CustomerJourneyMap(..), Header(..), Row(..), fromItems, toString)

import Models.Item as Item exposing (Item, ItemType(..), Items)


type CustomerJourneyMap
    = CustomerJourneyMap Header (List Row)


type Header
    = Header Items


type Row
    = Row Item


fromItems : Items -> CustomerJourneyMap
fromItems items =
    CustomerJourneyMap
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


toString : CustomerJourneyMap -> String
toString customerJourneyMap =
    let
        (CustomerJourneyMap h rows) =
            customerJourneyMap

        (Header headerItems) =
            h

        header =
            "|"
                ++ (Item.cons Item.emptyItem headerItems
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
