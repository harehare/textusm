module Views.Diagram.Table exposing (view)

import Models.Diagram as Diagram exposing (Model, Msg, SelectedItem, Settings)
import Models.Diagram.Table exposing (Header(..), Row(..), Table(..))
import Models.Item as Item exposing (Item, ItemType(..))
import Models.Property exposing (Property)
import String
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Keyed as Keyed
import Svg.Styled.Lazy as Lazy
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
            Svg.g
                []
                (Lazy.lazy4 headerView
                    model.settings
                    model.property
                    model.selectedItem
                    header
                    :: (rows
                            |> List.indexedMap
                                (\i (Row item) ->
                                    Lazy.lazy5 rowView
                                        model.settings
                                        model.property
                                        model.selectedItem
                                        (i + 1)
                                        item
                                )
                       )
                )

        _ ->
            Empty.view


headerView : Settings -> Property -> SelectedItem -> Item -> Svg Msg
headerView settings property selectedItem item =
    Svg.g []
        (Item.indexedMap
            (\i ii ->
                Lazy.lazy5 Views.grid settings property ( settings.size.width * i, 0 ) selectedItem (Item.withItemType Activities ii)
            )
            (Item.cons item (Item.unwrapChildren <| Item.getChildren item))
        )


rowView : Settings -> Property -> SelectedItem -> Int -> Item -> Svg Msg
rowView settings property selectedItem rowNo item =
    Keyed.node "g"
        []
        (( "row" ++ String.fromInt rowNo
         , Lazy.lazy5 Views.grid
            settings
            property
            ( 0, settings.size.height * rowNo )
            selectedItem
            (Item.withItemType Tasks item)
         )
            :: Item.indexedMap
                (\i childItem ->
                    ( "row" ++ String.fromInt (Item.getLineNo childItem)
                    , Lazy.lazy5 Views.grid
                        settings
                        property
                        ( settings.size.width * (i + 1), settings.size.height * rowNo )
                        selectedItem
                        (Item.withItemType Stories childItem)
                    )
                )
                (Item.getChildren item |> Item.unwrapChildren)
        )
