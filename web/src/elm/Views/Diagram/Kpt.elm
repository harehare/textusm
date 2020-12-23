module Views.Diagram.Kpt exposing (view)

import Constants
import Models.Diagram as Diagram exposing (Model, Msg(..))
import Models.Views.Kpt exposing (KptItem(..))
import Svg exposing (Svg, g)
import Svg.Lazy exposing (lazy5)
import Utils.Diagram as DiagramUtils
import Views.Diagram.Views as Views
import Views.Empty as Empty


view : Model -> Svg Msg
view model =
    case model.data of
        Diagram.Kpt k ->
            let
                itemHeight =
                    Basics.max Constants.itemHeight <| DiagramUtils.getCanvasHeight model.settings model.items

                (KptItem keep) =
                    k.keep

                (KptItem problem) =
                    k.problem

                (KptItem try) =
                    k.try
            in
            g
                []
                [ lazy5 Views.canvas
                    model.settings
                    ( Constants.largeItemWidth, itemHeight )
                    ( 0, 0 )
                    model.selectedItem
                    keep
                , lazy5 Views.canvas
                    model.settings
                    ( Constants.largeItemWidth, itemHeight )
                    ( 0, itemHeight - 5 )
                    model.selectedItem
                    problem
                , lazy5 Views.canvas
                    model.settings
                    ( Constants.largeItemWidth, itemHeight * 2 - 5 )
                    ( Constants.largeItemWidth - 5, 0 )
                    model.selectedItem
                    try
                ]

        _ ->
            Empty.view
