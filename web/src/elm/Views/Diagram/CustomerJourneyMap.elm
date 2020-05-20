module Views.Diagram.CustomerJourneyMap exposing (view)

import Data.Item as Item exposing (Item, ItemType(..), Items)
import Data.Position as Position
import Models.Diagram as Diagram exposing (Model, Msg(..), Settings)
import Models.Views.CustomerJourneyMap exposing (CustomerJourneyMap(..), Header(..), Row(..))
import String
import Svg exposing (Svg, g)
import Svg.Attributes exposing (fill, transform)
import Svg.Keyed as Keyed
import Svg.Lazy exposing (lazy3, lazy4)
import Views.Diagram.Views as Views
import Views.Empty as Empty


view : Model -> Svg Msg
view model =
    case model.data of
        Diagram.CustomerJourneyMap c ->
            let
                (CustomerJourneyMap h rows) =
                    c

                (Header header) =
                    h
            in
            g
                [ transform
                    ("translate("
                        ++ String.fromInt (Position.getX model.position)
                        ++ ","
                        ++ String.fromInt (Position.getY model.position)
                        ++ "), scale("
                        ++ String.fromFloat model.svg.scale
                        ++ ","
                        ++ String.fromFloat model.svg.scale
                        ++ ")"
                    )
                , fill model.settings.backgroundColor
                ]
                (lazy3 headerView
                    model.settings
                    model.selectedItem
                    header
                    :: (rows
                            |> List.indexedMap
                                (\i (Row item) ->
                                    lazy4 rowView
                                        model.settings
                                        model.selectedItem
                                        (i + 1)
                                        item
                                )
                       )
                )

        _ ->
            Empty.view


headerView : Settings -> Maybe Item -> Items -> Svg Msg
headerView settings selectedItem items =
    g []
        (lazy4 Views.cardView settings ( 0, 0 ) selectedItem Item.emptyItem
            :: Item.indexedMap
                (\i item ->
                    lazy4 Views.cardView settings ( settings.size.width * (i + 1), 0 ) selectedItem { item | itemType = Activities }
                )
                items
        )


rowView : Settings -> Maybe Item -> Int -> Item -> Svg Msg
rowView settings selectedItem rowNo item =
    Keyed.node "g"
        []
        (( "row" ++ String.fromInt rowNo
         , lazy4 Views.cardView
            settings
            ( 0, settings.size.height * rowNo )
            selectedItem
            { item | itemType = Tasks }
         )
            :: Item.indexedMap
                (\i childItem ->
                    ( "row" ++ String.fromInt childItem.lineNo
                    , lazy4 Views.cardView
                        settings
                        ( settings.size.width * (i + 1), settings.size.height * rowNo )
                        selectedItem
                        { childItem | itemType = Stories 1 }
                    )
                )
                (item.children |> Item.unwrapChildren)
        )
