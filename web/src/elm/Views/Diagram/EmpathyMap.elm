module Views.Diagram.EmpathyMap exposing (view)

import Constants
import Models.Diagram as Diagram exposing (Model, Msg)
import Models.Diagram.EmpathyMap exposing (EmpathyMapItem(..))
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Lazy as Lazy
import Utils.Diagram as DiagramUtils
import Views.Diagram.Views as Views
import Views.Empty as Empty


view : Model -> Svg Msg
view model =
    case model.data of
        Diagram.EmpathyMap e ->
            let
                itemHeight : Int
                itemHeight =
                    Basics.max Constants.itemHeight <| DiagramUtils.getCanvasHeight model.settings model.items

                (EmpathyMapItem says) =
                    e.says

                (EmpathyMapItem thinks) =
                    e.thinks

                (EmpathyMapItem does) =
                    e.does

                (EmpathyMapItem feels) =
                    e.feels
            in
            Svg.g
                []
                [ Lazy.lazy6 Views.canvas
                    model.settings
                    model.property
                    ( Constants.largeItemWidth, itemHeight )
                    ( 0, 0 )
                    model.selectedItem
                    says
                , Lazy.lazy6 Views.canvas
                    model.settings
                    model.property
                    ( Constants.largeItemWidth, itemHeight )
                    ( Constants.largeItemWidth - 5, 0 )
                    model.selectedItem
                    thinks
                , Lazy.lazy6 Views.canvasBottom
                    model.settings
                    model.property
                    ( Constants.largeItemWidth, itemHeight + 5 )
                    ( 0, itemHeight - 5 )
                    model.selectedItem
                    does
                , Lazy.lazy6 Views.canvasBottom
                    model.settings
                    model.property
                    ( Constants.largeItemWidth, itemHeight + 5 )
                    ( Constants.largeItemWidth - 5, itemHeight - 5 )
                    model.selectedItem
                    feels
                ]

        _ ->
            Empty.view
