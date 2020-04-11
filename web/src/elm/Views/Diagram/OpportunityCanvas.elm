module Views.Diagram.OpportunityCanvas exposing (view)

import Constants
import Models.Diagram exposing (Model, Msg(..))
import Models.Views.OpportunityCanvas as OpportunityCanvas exposing (OpportunityCanvasItem(..))
import String
import Svg exposing (Svg, g)
import Svg.Attributes exposing (fill, transform)
import Utils
import Views.Diagram.Views as Views


view : Model -> Svg Msg
view model =
    let
        itemHeight =
            Basics.max Constants.itemHeight <| Utils.getCanvasHeight model

        opportunityCanvas =
            OpportunityCanvas.fromItems model.items

        (OpportunityCanvasItem usersAndCustomers) =
            opportunityCanvas.usersAndCustomers

        (OpportunityCanvasItem problems) =
            opportunityCanvas.problems

        (OpportunityCanvasItem solutionsToday) =
            opportunityCanvas.solutionsToday

        (OpportunityCanvasItem solutionIdeas) =
            opportunityCanvas.solutionIdeas

        (OpportunityCanvasItem howWillUsersUseSolution) =
            opportunityCanvas.howWillUsersUseSolution

        (OpportunityCanvasItem adoptionStrategy) =
            opportunityCanvas.adoptionStrategy

        (OpportunityCanvasItem userMetrics) =
            opportunityCanvas.userMetrics

        (OpportunityCanvasItem businessChallenges) =
            opportunityCanvas.businessChallenges

        (OpportunityCanvasItem budget) =
            opportunityCanvas.budget

        (OpportunityCanvasItem businessBenefitsAndMetrics) =
            opportunityCanvas.businessBenefitsAndMetrics
    in
    g
        [ transform
            ("translate("
                ++ String.fromFloat
                    (if isInfinite <| model.x then
                        0

                     else
                        model.x
                    )
                ++ ","
                ++ String.fromFloat
                    (if isInfinite <| model.y then
                        0

                     else
                        model.y
                    )
                ++ ")"
            )
        , fill model.settings.backgroundColor
        ]
        [ Views.canvasView model.settings
            ( Constants.itemWidth, itemHeight * 2 )
            ( 0, 0 )
            model.selectedItem
            usersAndCustomers
        , Views.canvasView model.settings
            ( Constants.itemWidth, itemHeight )
            ( Constants.itemWidth - 5, 0 )
            model.selectedItem
            problems
        , Views.canvasView model.settings
            ( Constants.itemWidth, itemHeight + 5 )
            ( Constants.itemWidth - 5, itemHeight - 5 )
            model.selectedItem
            solutionsToday
        , Views.canvasView model.settings
            ( Constants.itemWidth, itemHeight * 2 )
            ( Constants.itemWidth * 2 - 10, 0 )
            model.selectedItem
            solutionIdeas
        , Views.canvasView model.settings
            ( Constants.itemWidth, itemHeight )
            ( Constants.itemWidth * 3 - 15, 0 )
            model.selectedItem
            howWillUsersUseSolution
        , Views.canvasView model.settings
            ( Constants.itemWidth, itemHeight + 5 )
            ( Constants.itemWidth * 3 - 15, itemHeight - 5 )
            model.selectedItem
            adoptionStrategy
        , Views.canvasView model.settings
            ( Constants.itemWidth, itemHeight * 2 )
            ( Constants.itemWidth * 4 - 20, 0 )
            model.selectedItem
            userMetrics
        , Views.canvasView model.settings
            ( round (toFloat Constants.itemWidth * 2) - 5, itemHeight + 5 )
            ( 0, itemHeight * 2 - 5 )
            model.selectedItem
            businessChallenges
        , Views.canvasView model.settings
            ( Constants.itemWidth, itemHeight + 5 )
            ( round (toFloat Constants.itemWidth * 2) - 10, itemHeight * 2 - 5 )
            model.selectedItem
            budget
        , Views.canvasView model.settings
            ( round (toFloat Constants.itemWidth * 2) - 5, itemHeight + 5 )
            ( round (toFloat Constants.itemWidth * 3) - 15, itemHeight * 2 - 5 )
            model.selectedItem
            businessBenefitsAndMetrics
        ]
