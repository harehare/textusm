module Views.Diagram.EmpathyMap exposing (view)

import Constants
import List.Extra exposing (getAt)
import Models.Diagram exposing (Model, Msg(..))
import Models.Item as Item exposing (ItemType(..))
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
    in
    g
        [ transform
            ("translate("
                ++ String.fromInt
                    (if isInfinite <| toFloat <| model.x then
                        0

                     else
                        model.x
                    )
                ++ ","
                ++ String.fromInt
                    (if isInfinite <| toFloat <| model.y then
                        0

                     else
                        model.y
                    )
                ++ ")"
            )
        , fill model.settings.backgroundColor
        ]
        [ -- SAYS
          Views.canvasView model.settings
            ( Constants.largeItemWidth, itemHeight )
            ( 0, 0 )
            model.selectedItem
            (model.items
                |> getAt 0
                |> Maybe.withDefault Item.emptyItem
            )

        -- THINKS
        , Views.canvasView model.settings
            ( Constants.largeItemWidth, itemHeight )
            ( Constants.largeItemWidth - 5, 0 )
            model.selectedItem
            (model.items
                |> getAt 1
                |> Maybe.withDefault Item.emptyItem
            )

        -- DOES
        , Views.canvasBottomView model.settings
            ( Constants.largeItemWidth, itemHeight + 5 )
            ( 0, itemHeight - 5 )
            model.selectedItem
            (model.items
                |> getAt 2
                |> Maybe.withDefault Item.emptyItem
            )

        -- FEELS
        , Views.canvasBottomView model.settings
            ( Constants.largeItemWidth, itemHeight + 5 )
            ( Constants.largeItemWidth - 5, itemHeight - 5 )
            model.selectedItem
            (model.items
                |> getAt 3
                |> Maybe.withDefault Item.emptyItem
            )
        ]
