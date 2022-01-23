module Views.Diagram.Kpt exposing (view)

import Constants
import Models.Diagram exposing (Model, Msg)
import Models.Diagram.Kpt exposing (KptItem(..))
import Models.DiagramData as DiagramData
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Lazy as Lazy
import Utils.Diagram as DiagramUtils
import Views.Diagram.Views as Views
import Views.Empty as Empty


view : Model -> Svg Msg
view model =
    case model.data of
        DiagramData.Kpt k ->
            let
                itemHeight : Int
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
                [ Lazy.lazy6 Views.canvas
                    model.settings
                    model.property
                    ( Constants.largeItemWidth, itemHeight )
                    ( 0, 0 )
                    model.selectedItem
                    keep
                , Lazy.lazy6 Views.canvas
                    model.settings
                    model.property
                    ( Constants.largeItemWidth, itemHeight )
                    ( 0, itemHeight - 5 )
                    model.selectedItem
                    problem
                , Lazy.lazy6 Views.canvas
                    model.settings
                    model.property
                    ( Constants.largeItemWidth, itemHeight * 2 - 5 )
                    ( Constants.largeItemWidth - 5, 0 )
                    model.selectedItem
                    try
                ]

        _ ->
            Empty.view
