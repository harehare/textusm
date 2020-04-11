module Views.Diagram.EmpathyMap exposing (view)

import Constants
import Models.Diagram exposing (Model, Msg(..))
import Models.Views.EmpathyMap as EmpathyMap exposing (EmpathyMapItem(..))
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

        empathyMap =
            EmpathyMap.fromItems model.items

        (EmpathyMapItem says) =
            empathyMap.says

        (EmpathyMapItem thinks) =
            empathyMap.thinks

        (EmpathyMapItem does) =
            empathyMap.does

        (EmpathyMapItem feels) =
            empathyMap.feels
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
            ( Constants.largeItemWidth, itemHeight )
            ( 0, 0 )
            model.selectedItem
            says
        , Views.canvasView model.settings
            ( Constants.largeItemWidth, itemHeight )
            ( Constants.largeItemWidth - 5, 0 )
            model.selectedItem
            thinks
        , Views.canvasBottomView model.settings
            ( Constants.largeItemWidth, itemHeight + 5 )
            ( 0, itemHeight - 5 )
            model.selectedItem
            does
        , Views.canvasBottomView model.settings
            ( Constants.largeItemWidth, itemHeight + 5 )
            ( Constants.largeItemWidth - 5, itemHeight - 5 )
            model.selectedItem
            feels
        ]
