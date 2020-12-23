module Views.Diagram.Table exposing (view)

import Data.Item as Item exposing (Item, ItemType(..))
import Models.Diagram as Diagram exposing (Model, Msg(..), SelectedItem, Settings)
import Models.Views.Table exposing (Header(..), Row(..), Table(..))
import String
import Svg exposing (Svg, g)
import Svg.Keyed as Keyed
import Svg.Lazy exposing (lazy3, lazy4)
import Views.Diagram.Views as Views
import Views.Empty as Empty


view : Model -> Svg Msg
view model =
    case model.data of
        Diagram.Table t ->
            let
                (Table h rows) =
                    t

                (Header header) =
                    h
            in
            g
                []
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


headerView : Settings -> SelectedItem -> Item -> Svg Msg
headerView settings selectedItem item =
    g []
        (Item.indexedMap
            (\i ii ->
                lazy4 Views.grid settings ( settings.size.width * i, 0 ) selectedItem (Item.withItemType Activities ii)
            )
            (Item.cons item (Item.unwrapChildren <| Item.getChildren item))
        )


rowView : Settings -> SelectedItem -> Int -> Item -> Svg Msg
rowView settings selectedItem rowNo item =
    Keyed.node "g"
        []
        (( "row" ++ String.fromInt rowNo
         , lazy4 Views.grid
            settings
            ( 0, settings.size.height * rowNo )
            selectedItem
            (Item.withItemType Tasks item)
         )
            :: Item.indexedMap
                (\i childItem ->
                    ( "row" ++ String.fromInt (Item.getLineNo childItem)
                    , lazy4 Views.grid
                        settings
                        ( settings.size.width * (i + 1), settings.size.height * rowNo )
                        selectedItem
                        (Item.withItemType (Stories 1) childItem)
                    )
                )
                (Item.getChildren item |> Item.unwrapChildren)
        )
