module Views.Diagram.UserPersona exposing (view)

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
            Basics.max Constants.itemHeight (14 * (List.maximum model.countByTasks |> Maybe.withDefault 0))
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
        [ -- Name
          Views.canvasImageView model.settings
            ( Constants.itemWidth, itemHeight )
            ( 0, 0 )
            (model.items
                |> getAt 0
                |> Maybe.withDefault Item.emptyItem
            )

        -- Who am i...
        , Views.canvasView model.settings
            ( Constants.itemWidth, itemHeight )
            ( Constants.itemWidth - 5, 0 )
            (model.items
                |> getAt 1
                |> Maybe.withDefault Item.emptyItem
            )

        -- three reasons to use your product
        , Views.canvasView model.settings
            ( round (Constants.itemWidth * 1.5 - 5), itemHeight )
            ( round (toFloat Constants.itemWidth * 2) - 10, 0 )
            (model.items
                |> getAt 2
                |> Maybe.withDefault Item.emptyItem
            )

        -- three reasons to buy your product
        , Views.canvasView model.settings
            ( round (Constants.itemWidth * 1.5), itemHeight )
            ( round (toFloat Constants.itemWidth * 3.5) - 20, 0 )
            (model.items
                |> getAt 3
                |> Maybe.withDefault Item.emptyItem
            )

        -- My interests
        , Views.canvasView model.settings
            ( Constants.itemWidth, itemHeight )
            ( 0, itemHeight - 5 )
            (model.items
                |> getAt 4
                |> Maybe.withDefault Item.emptyItem
            )

        -- My personality
        , Views.canvasView model.settings
            ( Constants.itemWidth, itemHeight )
            ( Constants.itemWidth - 5, itemHeight - 5 )
            (model.items
                |> getAt 5
                |> Maybe.withDefault Item.emptyItem
            )

        -- My skils
        , Views.canvasView model.settings
            ( Constants.itemWidth, itemHeight )
            ( Constants.itemWidth * 2 - 10, itemHeight - 5 )
            (model.items
                |> getAt 6
                |> Maybe.withDefault Item.emptyItem
            )

        -- My dreams
        , Views.canvasView model.settings
            ( Constants.itemWidth, itemHeight )
            ( Constants.itemWidth * 3 - 15, itemHeight - 5 )
            (model.items
                |> getAt 7
                |> Maybe.withDefault Item.emptyItem
            )

        -- My relationship with technology
        , Views.canvasView model.settings
            ( Constants.itemWidth, itemHeight )
            ( Constants.itemWidth * 4 - 20, itemHeight - 5 )
            (model.items
                |> getAt 8
                |> Maybe.withDefault Item.emptyItem
            )
        ]
