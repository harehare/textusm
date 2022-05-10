module Views.Diagram.Text exposing (view)

import Css exposing (property)
import Models.Color as Color
import Models.Diagram exposing (Msg, SelectedItem)
import Models.DiagramSettings as DiagramSettings
import Models.Item as Item exposing (Item)
import Models.ItemSettings as ItemSettings
import Models.Position exposing (Position)
import Models.Property exposing (Property)
import Svg.Styled exposing (Svg)
import Views.Diagram.Card as Card


view :
    { settings : DiagramSettings.Settings
    , property : Property
    , position : Position
    , selectedItem : SelectedItem
    , item : Item
    , canMove : Bool
    }
    -> Svg Msg
view { settings, property, position, selectedItem, item, canMove } =
    let
        item_ : Item
        item_ =
            item
                |> Item.withItemSettings
                    (Item.getItemSettings item
                        |> Maybe.withDefault ItemSettings.new
                        |> ItemSettings.withBackgroundColor (Just Color.transparent)
                        |> Just
                    )
    in
    Card.viewWithDefaultColor { settings = settings, property = property, position = position, selectedItem = selectedItem, item = item_, canMove = canMove }
