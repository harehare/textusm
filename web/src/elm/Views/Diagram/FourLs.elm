module Views.Diagram.FourLs exposing (view)

import Constants
import Models.Diagram as Diagram exposing (Model, Msg)
import Models.Diagram.FourLs exposing (FourLsItem(..))
import Svg.Styled as Svg exposing (Svg)
import Svg.Styled.Lazy as Lazy
import Utils.Diagram as DiagramUtils
import Views.Diagram.Views as Views
import Views.Empty as Empty


view : Model -> Svg Msg
view model =
    case model.data of
        Diagram.FourLs f ->
            let
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
                    ( Constants.largeItemWidth, itemHeight )
                    ( 0, 0 )
                    model.selectedItem
                    liked
                , Lazy.lazy6 Views.canvas
                    model.settings
                    model.property
                    ( Constants.largeItemWidth, itemHeight )
                    ( Constants.largeItemWidth - 5, 0 )
                    model.selectedItem
                    learned
                , Lazy.lazy6 Views.canvas
                    model.settings
                    model.property
                    ( Constants.largeItemWidth, itemHeight + 5 )
                    ( 0, itemHeight - 5 )
                    model.selectedItem
                    lacked
                , Lazy.lazy6 Views.canvas
                    model.settings
                    model.property
                    ( Constants.largeItemWidth, itemHeight + 5 )
                    ( Constants.largeItemWidth - 5, itemHeight - 5 )
                    model.selectedItem
                    longedFor
                ]

        _ ->
            Empty.view
