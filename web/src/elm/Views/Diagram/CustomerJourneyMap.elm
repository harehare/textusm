module Views.Diagram.CustomerJourneyMap exposing (view)

import Data.Item as Item exposing (Item, ItemType(..), Items)
import Models.Diagram exposing (Model, Msg(..), Settings)
import Models.Views.CustomerJourneyMap as CustomerJourneyMap exposing (CustomerJourneyMap(..), Header(..), Row(..))
import String
import Svg exposing (Svg, g)
import Svg.Attributes exposing (transform)
import Views.Diagram.Views as Views


view : Model -> Svg Msg
view model =
    let
        customerJourneyMap =
            CustomerJourneyMap.fromItems model.items

        (CustomerJourneyMap h rows) =
            customerJourneyMap

        (Header header) =
            h
    in
    g
        [ transform
            ("translate("
                ++ String.fromFloat
                    (if isInfinite <| model.x then
                        0

                     else
                        model.x
                    )
                ++ ","
                ++ String.fromFloat
                    (if isInfinite <| model.y then
                        0

                     else
                        model.y
                    )
                ++ ")"
            )
        ]
        (if Item.isEmpty model.items then
            []

         else
            headerView model.settings
                model.selectedItem
                header
                ++ (rows
                        |> List.indexedMap
                            (\i (Row item) ->
                                rowView model.settings
                                    model.selectedItem
                                    (i + 1)
                                    item
                            )
                        |> List.concat
                   )
        )


headerView : Settings -> Maybe Item -> Items -> List (Svg Msg)
headerView settings selectedItem items =
    Views.cardView settings ( 0, 0 ) selectedItem Item.emptyItem
        :: Item.indexedMap
            (\i item ->
                Views.cardView settings ( settings.size.width * (i + 1), 0 ) selectedItem { item | itemType = Activities }
            )
            items


rowView : Settings -> Maybe Item -> Int -> Item -> List (Svg Msg)
rowView settings selectedItem rowNo item =
    Views.cardView
        settings
        ( 0, settings.size.height * rowNo )
        selectedItem
        { item | itemType = Tasks }
        :: Item.indexedMap
            (\i childItem ->
                Views.cardView
                    settings
                    ( settings.size.width * (i + 1), settings.size.height * rowNo )
                    selectedItem
                    { childItem | itemType = Stories 1 }
            )
            (item.children |> Item.unwrapChildren)
