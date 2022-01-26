module Views.Diagram.BusinessModelCanvas exposing (view)

import Constants
import Models.Diagram exposing (Model, Msg)
import Models.Diagram.BusinessModelCanvas exposing (BusinessModelCanvasItem(..))
import Models.DiagramData as DiagramData
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Lazy as Lazy
import Utils.Diagram as DiagramUtils
import Views.Diagram.Views as Views
import Views.Empty as Empty


view : Model -> Svg Msg
view model =
    case model.data of
        DiagramData.BusinessModelCanvas b ->
            let
                itemHeight : Int
                itemHeight =
                    Basics.max Constants.itemHeight <| DiagramUtils.getCanvasHeight model.settings model.items

                (BusinessModelCanvasItem keyPartners) =
                    b.keyPartners

                (BusinessModelCanvasItem keyActivities) =
                    b.keyActivities

                (BusinessModelCanvasItem keyResources) =
                    b.keyResources

                (BusinessModelCanvasItem valuePropotion) =
                    b.valuePropotion

                (BusinessModelCanvasItem customerRelationships) =
                    b.customerRelationships

                (BusinessModelCanvasItem channels) =
                    b.channels

                (BusinessModelCanvasItem customerSegments) =
                    b.customerSegments

                (BusinessModelCanvasItem costStructure) =
                    b.costStructure

                (BusinessModelCanvasItem revenueStreams) =
                    b.revenueStreams
            in
            Svg.g
                []
                [ Lazy.lazy6 Views.canvas
                    model.settings
                    model.property
                    ( Constants.itemWidth - Constants.canvasOffset, itemHeight * 2 - Constants.canvasOffset )
                    ( 0, 0 )
                    model.selectedItem
                    keyPartners
                , Lazy.lazy6 Views.canvas
                    model.settings
                    model.property
                    ( Constants.itemWidth - Constants.canvasOffset, itemHeight - Constants.canvasOffset )
                    ( Constants.itemWidth - Constants.canvasOffset, 0 )
                    model.selectedItem
                    keyActivities
                , Lazy.lazy6 Views.canvas
                    model.settings
                    model.property
                    ( Constants.itemWidth - Constants.canvasOffset, itemHeight )
                    ( Constants.itemWidth - Constants.canvasOffset, itemHeight - Constants.canvasOffset )
                    model.selectedItem
                    keyResources
                , Lazy.lazy6 Views.canvas
                    model.settings
                    model.property
                    ( Constants.itemWidth - Constants.canvasOffset, itemHeight * 2 - Constants.canvasOffset )
                    ( Constants.itemWidth * 2 - Constants.canvasOffset * 2, 0 )
                    model.selectedItem
                    valuePropotion
                , Lazy.lazy6 Views.canvas
                    model.settings
                    model.property
                    ( Constants.itemWidth - Constants.canvasOffset, itemHeight - Constants.canvasOffset )
                    ( Constants.itemWidth * 3 - Constants.canvasOffset * 3, 0 )
                    model.selectedItem
                    customerRelationships
                , Lazy.lazy6 Views.canvas
                    model.settings
                    model.property
                    ( Constants.itemWidth - Constants.canvasOffset, itemHeight )
                    ( Constants.itemWidth * 3 - Constants.canvasOffset * 3, itemHeight - Constants.canvasOffset )
                    model.selectedItem
                    channels
                , Lazy.lazy6 Views.canvas
                    model.settings
                    model.property
                    ( Constants.itemWidth - Constants.canvasOffset, itemHeight * 2 - Constants.canvasOffset )
                    ( Constants.itemWidth * 4 - Constants.canvasOffset * 4, 0 )
                    model.selectedItem
                    customerSegments
                , Lazy.lazy6 Views.canvas
                    model.settings
                    model.property
                    ( round (toFloat Constants.itemWidth * 2.5) - Constants.canvasOffset * 3, itemHeight + Constants.canvasOffset )
                    ( 0, itemHeight * 2 - 5 )
                    model.selectedItem
                    costStructure
                , Lazy.lazy6 Views.canvas
                    model.settings
                    model.property
                    ( round (toFloat Constants.itemWidth * 2.5) - Constants.canvasOffset * 2, itemHeight + Constants.canvasOffset )
                    ( round (toFloat Constants.itemWidth * 2.5) - Constants.canvasOffset * 3, itemHeight * 2 - Constants.canvasOffset )
                    model.selectedItem
                    revenueStreams
                ]

        _ ->
            Empty.view
