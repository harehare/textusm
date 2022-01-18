module Views.Diagram.BusinessModelCanvas exposing (view)

import Constants
import Models.Diagram as Diagram exposing (Model, Msg)
import Models.Diagram.BusinessModelCanvas exposing (BusinessModelCanvasItem(..))
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Lazy as Lazy
import Utils.Diagram as DiagramUtils
import Views.Diagram.Views as Views
import Views.Empty as Empty


view : Model -> Svg Msg
view model =
    case model.data of
        Diagram.BusinessModelCanvas b ->
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
                    ( Constants.itemWidth, itemHeight * 2 )
                    ( 0, 0 )
                    model.selectedItem
                    keyPartners
                , Lazy.lazy6 Views.canvas
                    model.settings
                    model.property
                    ( Constants.itemWidth, itemHeight )
                    ( Constants.itemWidth - 5, 0 )
                    model.selectedItem
                    keyActivities
                , Lazy.lazy6 Views.canvas
                    model.settings
                    model.property
                    ( Constants.itemWidth, itemHeight + 5 )
                    ( Constants.itemWidth - 5, itemHeight - 5 )
                    model.selectedItem
                    keyResources
                , Lazy.lazy6 Views.canvas
                    model.settings
                    model.property
                    ( Constants.itemWidth, itemHeight * 2 )
                    ( Constants.itemWidth * 2 - 10, 0 )
                    model.selectedItem
                    valuePropotion
                , Lazy.lazy6 Views.canvas
                    model.settings
                    model.property
                    ( Constants.itemWidth, itemHeight )
                    ( Constants.itemWidth * 3 - 15, 0 )
                    model.selectedItem
                    customerRelationships
                , Lazy.lazy6 Views.canvas
                    model.settings
                    model.property
                    ( Constants.itemWidth, itemHeight + 5 )
                    ( Constants.itemWidth * 3 - 15, itemHeight - 5 )
                    model.selectedItem
                    channels
                , Lazy.lazy6 Views.canvas
                    model.settings
                    model.property
                    ( Constants.itemWidth, itemHeight * 2 )
                    ( Constants.itemWidth * 4 - 20, 0 )
                    model.selectedItem
                    customerSegments
                , Lazy.lazy6 Views.canvas
                    model.settings
                    model.property
                    ( round (toFloat Constants.itemWidth * 2.5) - 10, itemHeight + 5 )
                    ( 0, itemHeight * 2 - 5 )
                    model.selectedItem
                    costStructure
                , Lazy.lazy6 Views.canvas
                    model.settings
                    model.property
                    ( round (toFloat Constants.itemWidth * 2.5) - 5, itemHeight + 5 )
                    ( round (toFloat Constants.itemWidth * 2.5) - 15, itemHeight * 2 - 5 )
                    model.selectedItem
                    revenueStreams
                ]

        _ ->
            Empty.view
