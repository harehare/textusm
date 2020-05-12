module Views.Diagram.EmpathyMap exposing (view)

import Constants
import Data.Position as Position
import Models.Diagram as Diagram exposing (Model, Msg(..))
import Models.Views.EmpathyMap exposing (EmpathyMapItem(..))
import String
import Svg exposing (Svg, g)
import Svg.Attributes exposing (fill, transform)
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
                    Basics.max Constants.itemHeight <| Utils.getCanvasHeight model

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
                [ transform
                    ("translate("
                        ++ String.fromInt (Position.getX model.position)
                        ++ ","
                        ++ String.fromInt (Position.getY model.position)
                        ++ ")"
                    )
                , fill model.settings.backgroundColor
                ]
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
