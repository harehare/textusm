module Views.Diagram.Text exposing (view)

import Models.Color as Color
import Models.Diagram exposing (SelectedItem, SelectedItemInfo)
import Models.Diagram.Settings as DiagramSettings
import Models.Item as Item exposing (Item)
import Models.Item.Settings as ItemSettings
import Models.Position exposing (Position)
import Models.Property exposing (Property)
import Svg.Styled exposing (Svg)
import Views.Diagram.Card as Card
import Views.Diagram.Views as Views


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
