module Views.Diagram.StartStopContinue exposing (view)

import Constants
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
        [ -- Start
          Views.canvasView model.settings
            ( Constants.itemWidth, itemHeight )
            ( 0, 0 )
            model.selectedItem
            (model.items
                |> Item.getAt 0
                |> Maybe.withDefault Item.emptyItem
            )

        -- Stop
        , Views.canvasView model.settings
            ( Constants.itemWidth, itemHeight )
            ( Constants.itemWidth - 5, 0 )
            model.selectedItem
            (model.items
                |> Item.getAt 1
                |> Maybe.withDefault Item.emptyItem
            )

        -- Continue
        , Views.canvasView model.settings
            ( Constants.itemWidth, itemHeight )
            ( Constants.itemWidth * 2 - 10, 0 )
            model.selectedItem
            (model.items
                |> Item.getAt 2
                |> Maybe.withDefault Item.emptyItem
            )
        ]
