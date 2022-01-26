module Views.Diagram.OpportunityCanvas exposing (view)

import Constants
import Models.Diagram exposing (Model, Msg)
import Models.Diagram.OpportunityCanvas exposing (OpportunityCanvasItem(..))
import Models.DiagramData as DiagramData
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Lazy as Lazy
import Utils.Diagram as DiagramUtils
import Views.Diagram.Views as Views
import Views.Empty as Empty


view : Model -> Svg Msg
view model =
    case model.data of
        DiagramData.OpportunityCanvas o ->
            let
                itemHeight : Int
                itemHeight =
                    Basics.max Constants.itemHeight <| DiagramUtils.getCanvasHeight model.settings model.items

                (OpportunityCanvasItem usersAndCustomers) =
                    o.usersAndCustomers

                (OpportunityCanvasItem problems) =
                    o.problems

                (OpportunityCanvasItem solutionsToday) =
                    o.solutionsToday

                (OpportunityCanvasItem solutionIdeas) =
                    o.solutionIdeas

                (OpportunityCanvasItem howWillUsersUseSolution) =
                    o.howWillUsersUseSolution

                (OpportunityCanvasItem adoptionStrategy) =
                    o.adoptionStrategy

                (OpportunityCanvasItem userMetrics) =
                    o.userMetrics

                (OpportunityCanvasItem businessChallenges) =
                    o.businessChallenges

                (OpportunityCanvasItem budget) =
                    o.budget

                (OpportunityCanvasItem businessBenefitsAndMetrics) =
                    o.businessBenefitsAndMetrics
            in
            Svg.g
                []
                [ Lazy.lazy6 Views.canvas
                    model.settings
                    model.property
                    ( Constants.itemWidth - Constants.canvasOffset, itemHeight * 2 - Constants.canvasOffset )
                    ( 0, 0 )
                    model.selectedItem
                    usersAndCustomers
                , Lazy.lazy6 Views.canvas
                    model.settings
                    model.property
                    ( Constants.itemWidth - Constants.canvasOffset, itemHeight - Constants.canvasOffset )
                    ( Constants.itemWidth - Constants.canvasOffset, 0 )
                    model.selectedItem
                    problems
                , Lazy.lazy6 Views.canvas
                    model.settings
                    model.property
                    ( Constants.itemWidth - Constants.canvasOffset, itemHeight )
                    ( Constants.itemWidth - Constants.canvasOffset, itemHeight - Constants.canvasOffset )
                    model.selectedItem
                    solutionsToday
                , Lazy.lazy6 Views.canvas
                    model.settings
                    model.property
                    ( Constants.itemWidth - Constants.canvasOffset, itemHeight * 2 - Constants.canvasOffset )
                    ( Constants.itemWidth * 2 - Constants.canvasOffset * 2, 0 )
                    model.selectedItem
                    solutionIdeas
                , Lazy.lazy6 Views.canvas
                    model.settings
                    model.property
                    ( Constants.itemWidth - Constants.canvasOffset, itemHeight - Constants.canvasOffset )
                    ( Constants.itemWidth * 3 - Constants.canvasOffset * 3, 0 )
                    model.selectedItem
                    howWillUsersUseSolution
                , Lazy.lazy6 Views.canvas
                    model.settings
                    model.property
                    ( Constants.itemWidth - Constants.canvasOffset, itemHeight )
                    ( Constants.itemWidth * 3 - Constants.canvasOffset * 3, itemHeight - Constants.canvasOffset )
                    model.selectedItem
                    adoptionStrategy
                , Lazy.lazy6 Views.canvas
                    model.settings
                    model.property
                    ( Constants.itemWidth - Constants.canvasOffset, itemHeight * 2 - Constants.canvasOffset )
                    ( Constants.itemWidth * 4 - Constants.canvasOffset * 4, 0 )
                    model.selectedItem
                    userMetrics
                , Lazy.lazy6 Views.canvas
                    model.settings
                    model.property
                    ( round (toFloat Constants.itemWidth * 2) - Constants.canvasOffset * 2, itemHeight )
                    ( 0, itemHeight * 2 - Constants.canvasOffset )
                    model.selectedItem
                    businessChallenges
                , Lazy.lazy6 Views.canvas
                    model.settings
                    model.property
                    ( Constants.itemWidth - Constants.canvasOffset, itemHeight )
                    ( round (toFloat Constants.itemWidth * 2) - Constants.canvasOffset * 2, itemHeight * 2 - Constants.canvasOffset )
                    model.selectedItem
                    budget
                , Lazy.lazy6 Views.canvas
                    model.settings
                    model.property
                    ( round (toFloat Constants.itemWidth * 2) - Constants.canvasOffset * 2, itemHeight )
                    ( round (toFloat Constants.itemWidth * 3) - Constants.canvasOffset * 3, itemHeight * 2 - Constants.canvasOffset )
                    model.selectedItem
                    businessBenefitsAndMetrics
                ]

        _ ->
            Empty.view
