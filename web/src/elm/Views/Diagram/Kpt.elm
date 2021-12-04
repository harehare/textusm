module Views.Diagram.Kpt exposing (view)

import Constants
import Models.Diagram as Diagram exposing (Model, Msg)
import Models.Diagram.Kpt exposing (KptItem(..))
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Lazy as Lazy
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
            Svg.g
                []
                [ Lazy.lazy5 Views.canvas
                    model.settings
                    ( Constants.largeItemWidth, itemHeight )
                    ( 0, 0 )
                    model.selectedItem
                    keep
                , Lazy.lazy5 Views.canvas
                    model.settings
                    ( Constants.largeItemWidth, itemHeight )
                    ( 0, itemHeight - 5 )
                    model.selectedItem
                    problem
                , Lazy.lazy5 Views.canvas
                    model.settings
                    ( Constants.largeItemWidth, itemHeight * 2 - 5 )
                    ( Constants.largeItemWidth - 5, 0 )
                    model.selectedItem
                    try
                ]

        _ ->
            Empty.view
