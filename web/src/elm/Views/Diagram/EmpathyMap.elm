module Views.Diagram.EmpathyMap exposing (view)

import Constants
import Models.Diagram exposing (Model, Msg)
import Models.Diagram.EmpathyMap exposing (EmpathyMapItem(..))
import Models.DiagramData as DiagramData
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Lazy as Lazy
import Utils.Diagram as DiagramUtils
import Views.Diagram.Canvas as Canvas
import Views.Empty as Empty


view : Model -> Svg Msg
view model =
    case model.data of
        DiagramData.EmpathyMap e ->
            let
                (EmpathyMapItem does) =
                    e.does

                (EmpathyMapItem feels) =
                    e.feels

                itemHeight : Int
                itemHeight =
                    Basics.max Constants.itemHeight <| DiagramUtils.getCanvasHeight model.settings model.items

                (EmpathyMapItem says) =
                    e.says

                (EmpathyMapItem thinks) =
                    e.thinks
            in
            Svg.g
                []
                [ Lazy.lazy6 Canvas.view
                    model.settings
                    model.property
                    ( Constants.largeItemWidth - Constants.canvasOffset, itemHeight - Constants.canvasOffset )
                    ( 0, 0 )
                    model.selectedItem
                    says
                , Lazy.lazy6 Canvas.view
                    model.settings
                    model.property
                    ( Constants.largeItemWidth, itemHeight - Constants.canvasOffset )
                    ( Constants.largeItemWidth - 5, 0 )
                    model.selectedItem
                    thinks
                , Lazy.lazy6 Canvas.viewBottom
                    model.settings
                    model.property
                    ( Constants.largeItemWidth - Constants.canvasOffset, itemHeight + Constants.canvasOffset )
                    ( 0, itemHeight - Constants.canvasOffset )
                    model.selectedItem
                    does
                , Lazy.lazy6 Canvas.viewBottom
                    model.settings
                    model.property
                    ( Constants.largeItemWidth, itemHeight + Constants.canvasOffset )
                    ( Constants.largeItemWidth - Constants.canvasOffset, itemHeight - Constants.canvasOffset )
                    model.selectedItem
                    feels
                ]

        _ ->
            Empty.view
