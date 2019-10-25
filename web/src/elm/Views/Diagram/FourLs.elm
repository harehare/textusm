module Views.Diagram.FourLs exposing (view)

import Constants exposing (..)
import Html exposing (div)
import Html.Attributes as Attr
import List.Extra exposing (getAt)
import Models.Diagram as Diagram exposing (Model, Msg(..), Settings)
import Models.Item as Item exposing (Item, ItemType(..))
import String
import Svg exposing (..)
import Svg.Attributes exposing (..)
import Svg.Events exposing (..)
import Views.Diagram.Views as Views


view : Model -> Svg Msg
view model =
    let
        itemHeight =
            Basics.max Constants.largeItemHeight (14 * (List.maximum model.countByTasks |> Maybe.withDefault 0))
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
        [ -- Liked
          Views.canvasView model.settings
            ( Constants.largeItemWidth, itemHeight )
            ( 0, 0 )
            (model.items
                |> getAt 0
                |> Maybe.withDefault Item.emptyItem
            )

        -- Learned
        , Views.canvasView model.settings
            ( Constants.largeItemWidth, itemHeight )
            ( Constants.largeItemWidth - 5, 0 )
            (model.items
                |> getAt 1
                |> Maybe.withDefault Item.emptyItem
            )

        -- Lacked
        , Views.canvasView model.settings
            ( Constants.largeItemWidth, itemHeight + 5 )
            ( 0, itemHeight - 5 )
            (model.items
                |> getAt 2
                |> Maybe.withDefault Item.emptyItem
            )

        -- Longed for
        , Views.canvasView model.settings
            ( Constants.largeItemWidth, itemHeight + 5 )
            ( Constants.largeItemWidth - 5, itemHeight - 5 )
            (model.items
                |> getAt 3
                |> Maybe.withDefault Item.emptyItem
            )
        ]
