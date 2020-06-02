module Views.Diagram.Table exposing (view)

import Data.Item as Item exposing (Item, ItemType(..))
import Models.Diagram as Diagram exposing (Model, Msg(..), Settings)
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


headerView : Settings -> Maybe Item -> Item -> Svg Msg
headerView settings selectedItem item =
    g []
        (Item.indexedMap
            (\i ii ->
                lazy4 Views.gridView settings ( settings.size.width * i, 0 ) selectedItem { ii | itemType = Activities }
            )
            (Item.cons item (Item.unwrapChildren item.children))
        )


rowView : Settings -> Maybe Item -> Int -> Item -> Svg Msg
rowView settings selectedItem rowNo item =
    Keyed.node "g"
        []
        (( "row" ++ String.fromInt rowNo
         , lazy4 Views.gridView
            settings
            ( 0, settings.size.height * rowNo )
            selectedItem
            { item | itemType = Tasks }
         )
            :: Item.indexedMap
                (\i childItem ->
                    ( "row" ++ String.fromInt childItem.lineNo
                    , lazy4 Views.gridView
                        settings
                        ( settings.size.width * (i + 1), settings.size.height * rowNo )
                        selectedItem
                        { childItem | itemType = Stories 1 }
                    )
                )
                (item.children |> Item.unwrapChildren)
        )
