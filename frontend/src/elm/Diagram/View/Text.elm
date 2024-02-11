module Diagram.View.Text exposing (view)

import Diagram.Types exposing (SelectedItem, SelectedItemInfo)
import Diagram.Types.Settings as DiagramSettings
import Diagram.View.Card as Card
import Diagram.View.Views as Views
import Models.Color as Color
import Models.Item as Item exposing (Item)
import Models.Item.Settings as ItemSettings
import Models.Position exposing (Position)
import Models.Property exposing (Property)
import Svg.Styled exposing (Svg)


view :
    { settings : DiagramSettings.Settings
    , property : Property
    , position : Position
    , selectedItem : SelectedItem
    , item : Item
    , canMove : Bool
    , onEditSelectedItem : String -> msg
    , onEndEditSelectedItem : Item -> msg
    , onSelect : Maybe SelectedItemInfo -> msg
    , dragStart : Views.DragStart msg
    }
    -> Svg msg
view { settings, property, position, selectedItem, item, canMove, onEditSelectedItem, onEndEditSelectedItem, onSelect, dragStart } =
    let
        item_ : Item
        item_ =
            item
                |> Item.withSettings
                    (Item.getSettings item
                        |> Maybe.withDefault ItemSettings.new
                        |> ItemSettings.withBackgroundColor (Just Color.transparent)
                        |> Just
                    )
    in
    Card.viewWithDefaultColor
        { settings = settings
        , property = property
        , position = position
        , selectedItem = selectedItem
        , item = item_
        , canMove = canMove
        , onEditSelectedItem = onEditSelectedItem
        , onEndEditSelectedItem = onEndEditSelectedItem
        , onSelect = onSelect
        , dragStart = dragStart
        }
