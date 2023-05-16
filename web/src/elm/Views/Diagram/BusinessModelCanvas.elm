module Views.Diagram.BusinessModelCanvas exposing (docs, view)

import Constants
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter exposing (Chapter)
import Models.Diagram exposing (SelectedItem, SelectedItemInfo)
import Models.Diagram.BusinessModelCanvas as BusinessModelCanvas exposing (BusinessModelCanvasItem(..))
import Models.Diagram.Data as DiagramData
import Models.Diagram.Settings as DiagramSettings
import Models.Diagram.Type as DiagramType exposing (DiagramType(..))
import Models.Item as Item exposing (Item, Items)
import Models.Property as Property exposing (Property)
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Attributes as SvgAttr
import Svg.Styled.Lazy as Lazy
import Utils.Utils as Utils
import Views.Diagram.Canvas as Canvas
import Views.Diagram.Views as Views
import Views.Empty as Empty


view :
    { items : Items
    , data : DiagramData.Data
    , settings : DiagramSettings.Settings
    , selectedItem : SelectedItem
    , property : Property
    , onEditSelectedItem : String -> msg
    , onEndEditSelectedItem : Item -> msg
    , onSelect : Maybe SelectedItemInfo -> msg
    , dragStart : Views.DragStart msg
    }
    -> Svg msg
view { data, settings, items, property, selectedItem, onEditSelectedItem, onEndEditSelectedItem, onSelect, dragStart } =
    case data of
        DiagramData.BusinessModelCanvas b ->
            let
                (BusinessModelCanvasItem channels) =
                    b.channels

                (BusinessModelCanvasItem costStructure) =
                    b.costStructure

                (BusinessModelCanvasItem customerRelationships) =
                    b.customerRelationships

                (BusinessModelCanvasItem customerSegments) =
                    b.customerSegments

                itemHeight : Int
                itemHeight =
                    Basics.max Constants.itemHeight <| Utils.getCanvasHeight settings items

                (BusinessModelCanvasItem keyActivities) =
                    b.keyActivities

                (BusinessModelCanvasItem keyPartners) =
                    b.keyPartners

                (BusinessModelCanvasItem keyResources) =
                    b.keyResources

                (BusinessModelCanvasItem revenueStreams) =
                    b.revenueStreams

                (BusinessModelCanvasItem valuePropotion) =
                    b.valuePropotion
            in
            Svg.g
                []
                [ Lazy.lazy Canvas.view
                    { settings = settings
                    , property = property
                    , size = ( Constants.itemWidth - Constants.canvasOffset, itemHeight * 2 - Constants.canvasOffset )
                    , position = ( 0, 0 )
                    , selectedItem = selectedItem
                    , item = keyPartners
                    , onEditSelectedItem = onEditSelectedItem
                    , onEndEditSelectedItem = onEndEditSelectedItem
                    , onSelect = onSelect
                    , dragStart = dragStart
                    }
                , Lazy.lazy Canvas.view
                    { settings = settings
                    , property = property
                    , size = ( Constants.itemWidth - Constants.canvasOffset, itemHeight - Constants.canvasOffset )
                    , position = ( Constants.itemWidth - Constants.canvasOffset, 0 )
                    , selectedItem = selectedItem
                    , item = keyActivities
                    , onEditSelectedItem = onEditSelectedItem
                    , onEndEditSelectedItem = onEndEditSelectedItem
                    , onSelect = onSelect
                    , dragStart = dragStart
                    }
                , Lazy.lazy Canvas.view
                    { settings = settings
                    , property = property
                    , size = ( Constants.itemWidth - Constants.canvasOffset, itemHeight )
                    , position = ( Constants.itemWidth - Constants.canvasOffset, itemHeight - Constants.canvasOffset )
                    , selectedItem = selectedItem
                    , item = keyResources
                    , onEditSelectedItem = onEditSelectedItem
                    , onEndEditSelectedItem = onEndEditSelectedItem
                    , onSelect = onSelect
                    , dragStart = dragStart
                    }
                , Lazy.lazy Canvas.view
                    { settings = settings
                    , property = property
                    , size = ( Constants.itemWidth - Constants.canvasOffset, itemHeight * 2 - Constants.canvasOffset )
                    , position = ( Constants.itemWidth * 2 - Constants.canvasOffset * 2, 0 )
                    , selectedItem = selectedItem
                    , item = valuePropotion
                    , onEditSelectedItem = onEditSelectedItem
                    , onEndEditSelectedItem = onEndEditSelectedItem
                    , onSelect = onSelect
                    , dragStart = dragStart
                    }
                , Lazy.lazy Canvas.view
                    { settings = settings
                    , property = property
                    , size = ( Constants.itemWidth - Constants.canvasOffset, itemHeight - Constants.canvasOffset )
                    , position = ( Constants.itemWidth * 3 - Constants.canvasOffset * 3, 0 )
                    , selectedItem = selectedItem
                    , item = customerRelationships
                    , onEditSelectedItem = onEditSelectedItem
                    , onEndEditSelectedItem = onEndEditSelectedItem
                    , onSelect = onSelect
                    , dragStart = dragStart
                    }
                , Lazy.lazy Canvas.view
                    { settings = settings
                    , property = property
                    , size = ( Constants.itemWidth - Constants.canvasOffset, itemHeight )
                    , position = ( Constants.itemWidth * 3 - Constants.canvasOffset * 3, itemHeight - Constants.canvasOffset )
                    , selectedItem = selectedItem
                    , item = channels
                    , onEditSelectedItem = onEditSelectedItem
                    , onEndEditSelectedItem = onEndEditSelectedItem
                    , onSelect = onSelect
                    , dragStart = dragStart
                    }
                , Lazy.lazy Canvas.view
                    { settings = settings
                    , property = property
                    , size = ( Constants.itemWidth - Constants.canvasOffset, itemHeight * 2 - Constants.canvasOffset )
                    , position = ( Constants.itemWidth * 4 - Constants.canvasOffset * 4, 0 )
                    , selectedItem = selectedItem
                    , item = customerSegments
                    , onEditSelectedItem = onEditSelectedItem
                    , onEndEditSelectedItem = onEndEditSelectedItem
                    , onSelect = onSelect
                    , dragStart = dragStart
                    }
                , Lazy.lazy Canvas.view
                    { settings = settings
                    , property = property
                    , size = ( round (toFloat Constants.itemWidth * 2.5) - Constants.canvasOffset * 3, itemHeight + Constants.canvasOffset )
                    , position = ( 0, itemHeight * 2 - 5 )
                    , selectedItem = selectedItem
                    , item = costStructure
                    , onEditSelectedItem = onEditSelectedItem
                    , onEndEditSelectedItem = onEndEditSelectedItem
                    , onSelect = onSelect
                    , dragStart = dragStart
                    }
                , Lazy.lazy Canvas.view
                    { settings = settings
                    , property = property
                    , size = ( round (toFloat Constants.itemWidth * 2.5) - Constants.canvasOffset * 2, itemHeight + Constants.canvasOffset )
                    , position = ( round (toFloat Constants.itemWidth * 2.5) - Constants.canvasOffset * 3, itemHeight * 2 - Constants.canvasOffset )
                    , selectedItem = selectedItem
                    , item = revenueStreams
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
    Chapter.chapter "BusinessModelCanvas"
        |> Chapter.renderComponent
            (Svg.svg
                [ SvgAttr.width "100%"
                , SvgAttr.height "100%"
                , SvgAttr.viewBox "0 0 2048 2048"
                ]
                [ view
                    { items = Item.empty
                    , data =
                        DiagramData.BusinessModelCanvas <|
                            BusinessModelCanvas.from <|
                                (DiagramType.defaultText DiagramType.BusinessModelCanvas |> Item.fromString |> Tuple.second)
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
