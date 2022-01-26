module Views.Diagram.FourLs exposing (view)

import Constants
import Models.Diagram exposing (Model, Msg)
import Models.Diagram.FourLs exposing (FourLsItem(..))
import Models.DiagramData as DiagramData
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Lazy as Lazy
import Utils.Diagram as DiagramUtils
import Views.Diagram.Views as Views
import Views.Empty as Empty


view : Model -> Svg Msg
view model =
    case model.data of
        DiagramData.FourLs f ->
            let
                itemHeight : Int
                itemHeight =
                    Basics.max Constants.largeItemHeight <| DiagramUtils.getCanvasHeight model.settings model.items

                (FourLsItem liked) =
                    f.liked

                (FourLsItem learned) =
                    f.learned

                (FourLsItem lacked) =
                    f.lacked

                (FourLsItem longedFor) =
                    f.longedFor
            in
            Svg.g
                []
                [ Lazy.lazy6 Views.canvas
                    model.settings
                    model.property
                    ( Constants.largeItemWidth - Constants.canvasOffset, itemHeight - Constants.canvasOffset )
                    ( 0, 0 )
                    model.selectedItem
                    liked
                , Lazy.lazy6 Views.canvas
                    model.settings
                    model.property
                    ( Constants.largeItemWidth - Constants.canvasOffset, itemHeight - Constants.canvasOffset )
                    ( Constants.largeItemWidth - Constants.canvasOffset, 0 )
                    model.selectedItem
                    learned
                , Lazy.lazy6 Views.canvas
                    model.settings
                    model.property
                    ( Constants.largeItemWidth - Constants.canvasOffset, itemHeight )
                    ( 0, itemHeight - Constants.canvasOffset)
                    model.selectedItem
                    lacked
                , Lazy.lazy6 Views.canvas
                    model.settings
                    model.property
                    ( Constants.largeItemWidth - Constants.canvasOffset, itemHeight )
                    ( Constants.largeItemWidth - Constants.canvasOffset, itemHeight - 5 )
                    model.selectedItem
                    longedFor
                ]

        _ ->
            Empty.view
