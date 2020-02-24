module Views.Diagram.Kpt exposing (view)

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
        [ -- Keep
          Views.canvasView model.settings
            ( Constants.largeItemWidth, itemHeight )
            ( 0, 0 )
            model.selectedItem
            (model.items
                |> getAt 0
                |> Maybe.withDefault Item.emptyItem
            )

        -- Problem
        , Views.canvasView model.settings
            ( Constants.largeItemWidth, itemHeight )
            ( 0, itemHeight - 5 )
            model.selectedItem
            (model.items
                |> getAt 1
                |> Maybe.withDefault Item.emptyItem
            )

        -- Try
        , Views.canvasView model.settings
            ( Constants.largeItemWidth, itemHeight * 2 - 5 )
            ( Constants.largeItemWidth - 5, 0 )
            model.selectedItem
            (model.items
                |> getAt 2
                |> Maybe.withDefault Item.emptyItem
            )
        ]
