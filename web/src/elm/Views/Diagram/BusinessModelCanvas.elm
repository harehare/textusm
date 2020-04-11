module Views.Diagram.BusinessModelCanvas exposing (view)

import Constants
import Models.Diagram exposing (Model, Msg(..))
import Models.Views.BusinessModelCanvas as BusinessModelCanvas exposing (BusinessModelCanvasItem(..))
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

        businessModelCanvas =
            BusinessModelCanvas.fromItems model.items

        (BusinessModelCanvasItem keyPartners) =
            businessModelCanvas.keyPartners

        (BusinessModelCanvasItem keyActivities) =
            businessModelCanvas.keyActivities

        (BusinessModelCanvasItem keyResources) =
            businessModelCanvas.keyResources

        (BusinessModelCanvasItem valuePropotion) =
            businessModelCanvas.valuePropotion

        (BusinessModelCanvasItem customerRelationships) =
            businessModelCanvas.customerRelationships

        (BusinessModelCanvasItem channels) =
            businessModelCanvas.channels

        (BusinessModelCanvasItem customerSegments) =
            businessModelCanvas.customerSegments

        (BusinessModelCanvasItem costStructure) =
            businessModelCanvas.costStructure

        (BusinessModelCanvasItem revenueStreams) =
            businessModelCanvas.revenueStreams
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
            keyPartners
        , Views.canvasView model.settings
            ( Constants.itemWidth, itemHeight )
            ( Constants.itemWidth - 5, 0 )
            model.selectedItem
            keyActivities
        , Views.canvasView model.settings
            ( Constants.itemWidth, itemHeight + 5 )
            ( Constants.itemWidth - 5, itemHeight - 5 )
            model.selectedItem
            keyResources
        , Views.canvasView model.settings
            ( Constants.itemWidth, itemHeight * 2 )
            ( Constants.itemWidth * 2 - 10, 0 )
            model.selectedItem
            valuePropotion
        , Views.canvasView model.settings
            ( Constants.itemWidth, itemHeight )
            ( Constants.itemWidth * 3 - 15, 0 )
            model.selectedItem
            customerRelationships
        , Views.canvasView model.settings
            ( Constants.itemWidth, itemHeight + 5 )
            ( Constants.itemWidth * 3 - 15, itemHeight - 5 )
            model.selectedItem
            channels
        , Views.canvasView model.settings
            ( Constants.itemWidth, itemHeight * 2 )
            ( Constants.itemWidth * 4 - 20, 0 )
            model.selectedItem
            customerSegments
        , Views.canvasView model.settings
            ( round (toFloat Constants.itemWidth * 2.5) - 10, itemHeight + 5 )
            ( 0, itemHeight * 2 - 5 )
            model.selectedItem
            costStructure
        , Views.canvasView model.settings
            ( round (toFloat Constants.itemWidth * 2.5) - 5, itemHeight + 5 )
            ( round (toFloat Constants.itemWidth * 2.5) - 15, itemHeight * 2 - 5 )
            model.selectedItem
            revenueStreams
        ]
