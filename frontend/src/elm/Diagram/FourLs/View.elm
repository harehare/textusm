module Diagram.FourLs.View exposing (docs, view)

import Constants
import Diagram.FourLs.Types as FourLs exposing (FourLsItem(..))
import Diagram.Types exposing (SelectedItem, SelectedItemInfo)
import Diagram.Types.Data as DiagramData
import Diagram.Types.Settings as DiagramSettings
import Diagram.Types.Type as DiagramType
import Diagram.View.Canvas as Canvas
import Diagram.View.Views as View
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter exposing (Chapter)
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Attributes as SvgAttr
import Svg.Styled.Lazy as Lazy
import Types.Item as Item exposing (Item, Items)
import Types.Property as Property exposing (Property)
import Utils.Common as Utils
import View.Empty as Empty


view :
    { items : Items
    , data : DiagramData.Data
    , settings : DiagramSettings.Settings
    , selectedItem : SelectedItem
    , property : Property
    , onEditSelectedItem : String -> msg
    , onEndEditSelectedItem : Item -> msg
    , onSelect : Maybe SelectedItemInfo -> msg
    , dragStart : View.DragStart msg
    }
    -> Svg msg
view { data, settings, items, property, selectedItem, onEditSelectedItem, onEndEditSelectedItem, onSelect, dragStart } =
    case data of
        DiagramData.FourLs f ->
            let
                itemHeight : Int
                itemHeight =
                    Basics.max Constants.largeItemHeight <| Utils.getCanvasHeight settings items

                (FourLsItem lacked) =
                    f.lacked

                (FourLsItem learned) =
                    f.learned

                (FourLsItem liked) =
                    f.liked

                (FourLsItem longedFor) =
                    f.longedFor
            in
            Svg.g
                []
                [ Lazy.lazy Canvas.view
                    { settings = settings
                    , property = property
                    , size = ( Constants.largeItemWidth - Constants.canvasOffset, itemHeight - Constants.canvasOffset )
                    , position = ( 0, 0 )
                    , selectedItem = selectedItem
                    , item = liked
                    , onEditSelectedItem = onEditSelectedItem
                    , onEndEditSelectedItem = onEndEditSelectedItem
                    , onSelect = onSelect
                    , dragStart = dragStart
                    }
                , Lazy.lazy Canvas.view
                    { settings = settings
                    , property = property
                    , size = ( Constants.largeItemWidth - Constants.canvasOffset, itemHeight - Constants.canvasOffset )
                    , position = ( Constants.largeItemWidth - Constants.canvasOffset, 0 )
                    , selectedItem = selectedItem
                    , item = learned
                    , onEditSelectedItem = onEditSelectedItem
                    , onEndEditSelectedItem = onEndEditSelectedItem
                    , onSelect = onSelect
                    , dragStart = dragStart
                    }
                , Lazy.lazy Canvas.view
                    { settings = settings
                    , property = property
                    , size = ( Constants.largeItemWidth - Constants.canvasOffset, itemHeight )
                    , position = ( 0, itemHeight - Constants.canvasOffset )
                    , selectedItem = selectedItem
                    , item = lacked
                    , onEditSelectedItem = onEditSelectedItem
                    , onEndEditSelectedItem = onEndEditSelectedItem
                    , onSelect = onSelect
                    , dragStart = dragStart
                    }
                , Lazy.lazy Canvas.view
                    { settings = settings
                    , property = property
                    , size = ( Constants.largeItemWidth - Constants.canvasOffset, itemHeight )
                    , position = ( Constants.largeItemWidth - Constants.canvasOffset, itemHeight - 5 )
                    , selectedItem = selectedItem
                    , item = longedFor
                    , onEditSelectedItem = onEditSelectedItem
                    , onEndEditSelectedItem = onEndEditSelectedItem
                    , onSelect = onSelect
                    , dragStart = dragStart
                    }
                ]

        _ ->
            Empty.view


docs : Chapter x
docs =
    Chapter.chapter "FourLs"
        |> Chapter.renderComponent
            (Svg.svg
                [ SvgAttr.width "100%"
                , SvgAttr.height "100%"
                , SvgAttr.viewBox "0 0 2048 2048"
                ]
                [ view
                    { items = Item.empty
                    , data =
                        DiagramData.FourLs <|
                            FourLs.from <|
                                (DiagramType.defaultText DiagramType.Fourls |> Item.fromString |> Tuple.second)
                    , settings = DiagramSettings.default
                    , selectedItem = Nothing
                    , property = Property.empty
                    , onEditSelectedItem = \_ -> Actions.logAction "onEditSelectedItem"
                    , onEndEditSelectedItem = \_ -> Actions.logAction "onEndEditSelectedItem"
                    , onSelect = \_ -> Actions.logAction "onEndEditSelectedItem"
                    , dragStart = \_ _ -> SvgAttr.style ""
                    }
                ]
                |> Svg.toUnstyled
            )
