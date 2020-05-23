module Views.Diagram.Kpt exposing (view)

import Constants
import Data.Position as Position
import Models.Diagram as Diagram exposing (Model, Msg(..))
import Models.Views.Kpt exposing (KptItem(..))
import String
import Svg exposing (Svg, g)
import Svg.Attributes exposing (fill, style, transform)
import Svg.Lazy exposing (lazy5)
import Utils
import Views.Diagram.Views as Views
import Views.Empty as Empty


view : Model -> Svg Msg
view model =
    case model.data of
        Diagram.Kpt k ->
            let
                itemHeight =
                    Basics.max Constants.itemHeight <| Utils.getCanvasHeight model.settings model.items

                (KptItem keep) =
                    k.keep

                (KptItem problem) =
                    k.problem

                (KptItem try) =
                    k.try
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
                , if model.moveStart then
                    style "will-change: transform;"

                  else
                    style "will-change: transform;transition: transform 0.15s ease"
                ]
                [ lazy5 Views.canvasView
                    model.settings
                    ( Constants.largeItemWidth, itemHeight )
                    ( 0, 0 )
                    model.selectedItem
                    keep
                , lazy5 Views.canvasView
                    model.settings
                    ( Constants.largeItemWidth, itemHeight )
                    ( 0, itemHeight - 5 )
                    model.selectedItem
                    problem
                , lazy5 Views.canvasView
                    model.settings
                    ( Constants.largeItemWidth, itemHeight * 2 - 5 )
                    ( Constants.largeItemWidth - 5, 0 )
                    model.selectedItem
                    try
                ]

        _ ->
            Empty.view
