module Views.Diagram.OpportunityCanvas exposing (view)

import Constants
import Models.Diagram as Diagram exposing (Model, Msg)
import Models.Diagram.OpportunityCanvas exposing (OpportunityCanvasItem(..))
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Lazy as Lazy
import Utils.Diagram as DiagramUtils
import Views.Diagram.Views as Views
import Views.Empty as Empty


view : Model -> Svg Msg
view model =
    case model.data of
        Diagram.OpportunityCanvas o ->
            let
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
                    ( Constants.itemWidth, itemHeight * 2 )
                    ( 0, 0 )
                    model.selectedItem
                    usersAndCustomers
                , Lazy.lazy6 Views.canvas
                    model.settings
                    model.property
                    ( Constants.itemWidth, itemHeight )
                    ( Constants.itemWidth - 5, 0 )
                    model.selectedItem
                    problems
                , Lazy.lazy6 Views.canvas
                    model.settings
                    model.property
                    ( Constants.itemWidth, itemHeight + 5 )
                    ( Constants.itemWidth - 5, itemHeight - 5 )
                    model.selectedItem
                    solutionsToday
                , Lazy.lazy6 Views.canvas
                    model.settings
                    model.property
                    ( Constants.itemWidth, itemHeight * 2 )
                    ( Constants.itemWidth * 2 - 10, 0 )
                    model.selectedItem
                    solutionIdeas
                , Lazy.lazy6 Views.canvas
                    model.settings
                    model.property
                    ( Constants.itemWidth, itemHeight )
                    ( Constants.itemWidth * 3 - 15, 0 )
                    model.selectedItem
                    howWillUsersUseSolution
                , Lazy.lazy6 Views.canvas
                    model.settings
                    model.property
                    ( Constants.itemWidth, itemHeight + 5 )
                    ( Constants.itemWidth * 3 - 15, itemHeight - 5 )
                    model.selectedItem
                    adoptionStrategy
                , Lazy.lazy6 Views.canvas
                    model.settings
                    model.property
                    ( Constants.itemWidth, itemHeight * 2 )
                    ( Constants.itemWidth * 4 - 20, 0 )
                    model.selectedItem
                    userMetrics
                , Lazy.lazy6 Views.canvas
                    model.settings
                    model.property
                    ( round (toFloat Constants.itemWidth * 2) - 5, itemHeight + 5 )
                    ( 0, itemHeight * 2 - 5 )
                    model.selectedItem
                    businessChallenges
                , Lazy.lazy6 Views.canvas
                    model.settings
                    model.property
                    ( Constants.itemWidth, itemHeight + 5 )
                    ( round (toFloat Constants.itemWidth * 2) - 10, itemHeight * 2 - 5 )
                    model.selectedItem
                    budget
                , Lazy.lazy6 Views.canvas
                    model.settings
                    model.property
                    ( round (toFloat Constants.itemWidth * 2) - 5, itemHeight + 5 )
                    ( round (toFloat Constants.itemWidth * 3) - 15, itemHeight * 2 - 5 )
                    model.selectedItem
                    businessBenefitsAndMetrics
                ]

        _ ->
            Empty.view
