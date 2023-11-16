module Views.Diagram.Table exposing (docs, view)

import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter exposing (Chapter)
import Models.Diagram exposing (SelectedItem, SelectedItemInfo)
import Models.Diagram.CardSize as CardSize exposing (CardSize)
import Models.Diagram.Data as DiagramData
import Models.Diagram.Settings as DiagramSettings
import Models.Diagram.Table as Table exposing (Header(..), Row(..), Table(..))
import Models.Diagram.Type as DiagramType
import Models.Item as Item exposing (Item)
import Models.Property as Property exposing (Property)
import String
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Attributes as SvgAttr
import Svg.Styled.Keyed as Keyed
import Svg.Styled.Lazy as Lazy
import Views.Diagram.Grid as Grid
import Views.Empty as Empty


view :
    { data : DiagramData.Data
    , settings : DiagramSettings.Settings
    , selectedItem : SelectedItem
    , property : Property
    , onEditSelectedItem : String -> msg
    , onEndEditSelectedItem : Item -> msg
    , onSelect : Maybe SelectedItemInfo -> msg
    }
    -> Svg msg
view { data, settings, property, selectedItem, onEditSelectedItem, onEndEditSelectedItem, onSelect } =
    case data of
        DiagramData.Table t ->
            let
                (Table h rows) =
                    t

                (Header header) =
                    h
            in
            Svg.g
                []
                (Lazy.lazy headerView
                    { settings = settings
                    , property = property
                    , selectedItem = selectedItem
                    , item = header
                    , onEditSelectedItem = onEditSelectedItem
                    , onEndEditSelectedItem = onEndEditSelectedItem
                    , onSelect = onSelect
                    }
                    :: (rows
                            |> List.indexedMap
                                (\i (Row item) ->
                                    Lazy.lazy rowView
                                        { settings = settings
                                        , property = property
                                        , selectedItem = selectedItem
                                        , rowNo = i + 1
                                        , item = item
                                        , onEditSelectedItem = onEditSelectedItem
                                        , onEndEditSelectedItem = onEndEditSelectedItem
                                        , onSelect = onSelect
                                        }
                                )
                       )
                )

        _ ->
            Empty.view


headerView :
    { settings : DiagramSettings.Settings
    , property : Property
    , selectedItem : SelectedItem
    , item : Item
    , onEditSelectedItem : String -> msg
    , onEndEditSelectedItem : Item -> msg
    , onSelect : Maybe SelectedItemInfo -> msg
    }
    -> Svg msg
headerView { settings, property, selectedItem, item, onEditSelectedItem, onEndEditSelectedItem, onSelect } =
    Svg.g []
        (Item.indexedMap
            (\i ii ->
                Lazy.lazy Grid.view
                    { settings = settings
                    , property = property
                    , position = ( CardSize.toInt settings.size.width * i, 0 )
                    , selectedItem = selectedItem
                    , item = ii
                    , onEditSelectedItem = onEditSelectedItem
                    , onEndEditSelectedItem = onEndEditSelectedItem
                    , onSelect = onSelect
                    }
            )
            (Item.cons item (Item.unwrapChildren <| Item.getChildren item))
        )


rowView :
    { settings : DiagramSettings.Settings
    , property : Property
    , selectedItem : SelectedItem
    , rowNo : Int
    , item : Item
    , onEditSelectedItem : String -> msg
    , onEndEditSelectedItem : Item -> msg
    , onSelect : Maybe SelectedItemInfo -> msg
    }
    -> Svg msg
rowView { settings, property, selectedItem, rowNo, item, onEditSelectedItem, onEndEditSelectedItem, onSelect } =
    Keyed.node "g"
        []
        (( "row" ++ String.fromInt rowNo
         , Lazy.lazy Grid.view
            { settings = settings
            , property = property
            , position = ( 0, CardSize.toInt settings.size.height * rowNo )
            , selectedItem = selectedItem
            , item = item
            , onEditSelectedItem = onEditSelectedItem
            , onEndEditSelectedItem = onEndEditSelectedItem
            , onSelect = onSelect
            }
         )
            :: Item.indexedMap
                (\i childItem ->
                    ( "row" ++ String.fromInt (Item.getLineNo childItem)
                    , Lazy.lazy Grid.view
                        { settings = settings
                        , property = property
                        , position = ( CardSize.toInt settings.size.width * (i + 1), CardSize.toInt settings.size.height * rowNo )
                        , selectedItem = selectedItem
                        , item = childItem
                        , onEditSelectedItem = onEditSelectedItem
                        , onEndEditSelectedItem = onEndEditSelectedItem
                        , onSelect = onSelect
                        }
                    )
                )
                (Item.getChildren item |> Item.unwrapChildren)
        )


docs : Chapter x
docs =
    Chapter.chapter "Table"
        |> Chapter.renderComponent
            (Svg.svg
                [ SvgAttr.width "100%"
                , SvgAttr.height "100%"
                , SvgAttr.viewBox "0 0 2048 2048"
                ]
                [ view
                    { data =
                        DiagramData.Table <|
                            Table.from <|
                                (DiagramType.defaultText DiagramType.Table |> Item.fromString |> Tuple.second)
                    , settings = DiagramSettings.default
                    , selectedItem = Nothing
                    , property = Property.empty
                    , onEditSelectedItem = \_ -> Actions.logAction "onEditSelectedItem"
                    , onEndEditSelectedItem = \_ -> Actions.logAction "onEndEditSelectedItem"
                    , onSelect = \_ -> Actions.logAction "onEndEditSelectedItem"
                    }
                ]
                |> Svg.toUnstyled
            )
