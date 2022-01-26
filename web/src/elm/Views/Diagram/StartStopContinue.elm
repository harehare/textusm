module Views.Diagram.StartStopContinue exposing (view)

import Constants
import Models.Diagram exposing (Model, Msg)
import Models.Diagram.StartStopContinue exposing (StartStopContinueItem(..))
import Models.DiagramData as DiagramData
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Lazy as Lazy
import Utils.Diagram as DiagramUtils
import Views.Diagram.Views as Views
import Views.Empty as Empty


view : Model -> Svg Msg
view model =
    case model.data of
        DiagramData.StartStopContinue s ->
            let
                itemHeight : Int
                itemHeight =
                    Basics.max Constants.itemHeight <| DiagramUtils.getCanvasHeight model.settings model.items

                (StartStopContinueItem start) =
                    s.start

                (StartStopContinueItem stop) =
                    s.stop

                (StartStopContinueItem continue) =
                    s.continue
            in
            Svg.g
                []
                [ Lazy.lazy6 Views.canvas
                    model.settings
                    model.property
                    ( Constants.itemWidth - Constants.canvasOffset, itemHeight - Constants.canvasOffset )
                    ( 0, 0 )
                    model.selectedItem
                    start
                , Lazy.lazy6 Views.canvas
                    model.settings
                    model.property
                    ( Constants.itemWidth - Constants.canvasOffset, itemHeight - Constants.canvasOffset )
                    ( Constants.itemWidth - Constants.canvasOffset, 0 )
                    model.selectedItem
                    stop
                , Lazy.lazy6 Views.canvas
                    model.settings
                    model.property
                    ( Constants.itemWidth - Constants.canvasOffset, itemHeight - Constants.canvasOffset )
                    ( Constants.itemWidth * 2 - Constants.canvasOffset * 2, 0 )
                    model.selectedItem
                    continue
                ]

        _ ->
            Empty.view
