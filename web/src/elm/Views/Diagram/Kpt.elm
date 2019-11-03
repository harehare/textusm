module Views.Diagram.Kpt exposing (view)

import Constants exposing (..)
import List.Extra exposing (getAt)
import Models.Diagram exposing (Model, Msg(..))
import Models.Item as Item exposing (ItemType(..))
import String
import Svg exposing (..)
import Svg.Attributes exposing (..)
import Svg.Events exposing (..)
import Views.Diagram.Views as Views


view : Model -> Svg Msg
view model =
    let
        itemHeight =
            Basics.max Constants.itemHeight (30 * (List.maximum model.countByTasks |> Maybe.withDefault 0))
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
        [ -- Keep
          Views.canvasView model.settings
            ( Constants.largeItemWidth, itemHeight )
            ( 0, 0 )
            (model.items
                |> getAt 0
                |> Maybe.withDefault Item.emptyItem
            )

        -- Problem
        , Views.canvasView model.settings
            ( Constants.largeItemWidth, itemHeight )
            ( 0, itemHeight - 5 )
            (model.items
                |> getAt 1
                |> Maybe.withDefault Item.emptyItem
            )

        -- Try
        , Views.canvasView model.settings
            ( Constants.largeItemWidth, itemHeight * 2 - 5 )
            ( Constants.largeItemWidth - 5, 0 )
            (model.items
                |> getAt 2
                |> Maybe.withDefault Item.emptyItem
            )
        ]
