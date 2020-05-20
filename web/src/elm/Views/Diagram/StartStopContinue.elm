module Views.Diagram.StartStopContinue exposing (view)

import Constants
import Data.Position as Position
import Models.Diagram as Diagram exposing (Model, Msg(..))
import Models.Views.StartStopContinue exposing (StartStopContinueItem(..))
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
        Diagram.StartStopContinue s ->
            let
                itemHeight =
                    Basics.max Constants.itemHeight <| Utils.getCanvasHeight model

                (StartStopContinueItem start) =
                    s.start

                (StartStopContinueItem stop) =
                    s.stop

                (StartStopContinueItem continue) =
                    s.continue
            in
            g
                [ transform
                    ("translate("
                        ++ String.fromInt (Position.getX model.position)
                        ++ ","
                        ++ String.fromInt (Position.getY model.position)
                        ++ "), scale("
                        ++ String.fromFloat model.svg.scale
                        ++ ","
                        ++ String.fromFloat model.svg.scale
                        ++ ")"
                    )
                , fill model.settings.backgroundColor
                ]
                [ lazy5 Views.canvasView
                    model.settings
                    ( Constants.itemWidth, itemHeight )
                    ( 0, 0 )
                    model.selectedItem
                    start
                , lazy5 Views.canvasView
                    model.settings
                    ( Constants.itemWidth, itemHeight )
                    ( Constants.itemWidth - 5, 0 )
                    model.selectedItem
                    stop
                , lazy5 Views.canvasView
                    model.settings
                    ( Constants.itemWidth, itemHeight )
                    ( Constants.itemWidth * 2 - 10, 0 )
                    model.selectedItem
                    continue
                ]

        _ ->
            Empty.view
