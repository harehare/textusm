module Views.Diagram.EmpathyMap exposing (view)

import Constants
import Models.Diagram as Diagram exposing (Model, Msg(..))
import Models.Views.EmpathyMap exposing (EmpathyMapItem(..))
import Svg exposing (Svg, g)
import Svg.Lazy exposing (lazy5)
import Utils
import Views.Diagram.Views as Views
import Views.Empty as Empty


view : Model -> Svg Msg
view model =
    case model.data of
        Diagram.EmpathyMap e ->
            let
                itemHeight =
                    Basics.max Constants.itemHeight <| Utils.getCanvasHeight model.settings model.items

                (EmpathyMapItem says) =
                    e.says

                (EmpathyMapItem thinks) =
                    e.thinks

                (EmpathyMapItem does) =
                    e.does

                (EmpathyMapItem feels) =
                    e.feels
            in
            g
                []
                [ lazy5 Views.canvasView
                    model.settings
                    ( Constants.largeItemWidth, itemHeight )
                    ( 0, 0 )
                    model.selectedItem
                    says
                , lazy5 Views.canvasView
                    model.settings
                    ( Constants.largeItemWidth, itemHeight )
                    ( Constants.largeItemWidth - 5, 0 )
                    model.selectedItem
                    thinks
                , lazy5 Views.canvasBottomView
                    model.settings
                    ( Constants.largeItemWidth, itemHeight + 5 )
                    ( 0, itemHeight - 5 )
                    model.selectedItem
                    does
                , lazy5 Views.canvasBottomView
                    model.settings
                    ( Constants.largeItemWidth, itemHeight + 5 )
                    ( Constants.largeItemWidth - 5, itemHeight - 5 )
                    model.selectedItem
                    feels
                ]

        _ ->
            Empty.view
