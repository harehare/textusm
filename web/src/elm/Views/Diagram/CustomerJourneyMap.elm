module Views.Diagram.CustomerJourneyMap exposing (view)

import Models.Diagram exposing (Model, Msg(..), Settings)
import Models.Item as Item exposing (Item, ItemType(..))
import String
import Svg exposing (Svg, g)
import Svg.Attributes exposing (transform)
import Views.Diagram.Views as Views


view : Model -> Svg Msg
view model =
    g
        [ transform
            ("translate("
                ++ String.fromInt
                    (if isInfinite <| toFloat <| model.x then
                        0

                     else
                        model.x
                    )
                ++ ","
                ++ String.fromInt
                    (if isInfinite <| toFloat <| model.y then
                        0

                     else
                        model.y
                    )
                ++ ")"
            )
        ]
        (if List.isEmpty model.items then
            []

         else
            headerView model.settings model.selectedItem model.items
                ++ rowView model.settings
                    model.selectedItem
                    (model.items
                        |> List.head
                        |> Maybe.withDefault Item.emptyItem
                        |> .children
                        |> Item.unwrapChildren
                    )
                ++ (model.items
                        |> List.indexedMap
                            (\i item ->
                                columnView model.settings (i + 1) model.selectedItem (Item.unwrapChildren item.children)
                            )
                        |> List.concat
                   )
        )


headerView : Settings -> Maybe Item -> List Item -> List (Svg Msg)
headerView settings selectedItem items =
    Views.readOnlyCardView settings ( 0, 0 ) selectedItem Item.emptyItem
        :: List.indexedMap
            (\i item ->
                Views.readOnlyCardView settings ( settings.size.width * (i + 1), 0 ) selectedItem item
            )
            items


rowView : Settings -> Maybe Item -> List Item -> List (Svg Msg)
rowView settings selectedItem items =
    List.indexedMap
        (\i item ->
            Views.readOnlyCardView
                settings
                ( 0, settings.size.height * (i + 1) )
                selectedItem
                item
        )
        items


columnView : Settings -> Int -> Maybe Item -> List Item -> List (Svg Msg)
columnView settings index selectedItem items =
    List.indexedMap
        (\i item ->
            let
                text =
                    Item.unwrapChildren item.children
                        |> List.map (\ii -> ii.text)
                        |> String.join "\n"
            in
            Views.readOnlyCardView
                settings
                ( settings.size.width * index, settings.size.height * (i + 1) )
                selectedItem
                { item | text = text, itemType = Stories 1 }
        )
        items
