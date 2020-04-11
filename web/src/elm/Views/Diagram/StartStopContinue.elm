module Views.Diagram.StartStopContinue exposing (view)

import Constants
import Models.Diagram exposing (Model, Msg(..))
import Models.Views.StartStopContinue as StartStopContinue exposing (StartStopContinueItem(..))
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

        startStopContinue =
            StartStopContinue.fromItems model.items

        (StartStopContinueItem start) =
            startStopContinue.start

        (StartStopContinueItem stop) =
            startStopContinue.stop

        (StartStopContinueItem continue) =
            startStopContinue.continue
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
            ( Constants.itemWidth, itemHeight )
            ( 0, 0 )
            model.selectedItem
            start
        , Views.canvasView model.settings
            ( Constants.itemWidth, itemHeight )
            ( Constants.itemWidth - 5, 0 )
            model.selectedItem
            stop
        , Views.canvasView model.settings
            ( Constants.itemWidth, itemHeight )
            ( Constants.itemWidth * 2 - 10, 0 )
            model.selectedItem
            continue
        ]
