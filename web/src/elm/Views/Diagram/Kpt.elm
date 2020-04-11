module Views.Diagram.Kpt exposing (view)

import Constants
import Models.Diagram exposing (Model, Msg(..))
import Models.Views.Kpt as Kpt exposing (KptItem(..))
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

        kpt =
            Kpt.fromItems model.items

        (KptItem keep) =
            kpt.keep

        (KptItem problem) =
            kpt.problem

        (KptItem try) =
            kpt.try
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
            keep
        , Views.canvasView model.settings
            ( Constants.largeItemWidth, itemHeight )
            ( 0, itemHeight - 5 )
            model.selectedItem
            problem
        , Views.canvasView model.settings
            ( Constants.largeItemWidth, itemHeight * 2 - 5 )
            ( Constants.largeItemWidth - 5, 0 )
            model.selectedItem
            try
        ]
