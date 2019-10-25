module Views.Diagram.OpportunityCanvas exposing (view)

import Constants exposing (..)
import Html exposing (div)
import Html.Attributes as Attr
import List.Extra exposing (getAt)
import Models.Diagram as Diagram exposing (Model, Msg(..), Settings)
import Models.Item as Item exposing (Children(..), Item, ItemType(..))
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
        [ -- Users and Customers
          Views.canvasView model.settings
            ( Constants.itemWidth, itemHeight * 2 )
            ( 0, 0 )
            (model.items
                |> getAt 2
                |> Maybe.withDefault Item.emptyItem
            )

        -- Problems
        , Views.canvasView model.settings
            ( Constants.itemWidth, itemHeight )
            ( Constants.itemWidth - 5, 0 )
            (model.items
                |> getAt 0
                |> Maybe.withDefault Item.emptyItem
            )

        -- Solutions Today
        , Views.canvasView model.settings
            ( Constants.itemWidth, itemHeight + 5 )
            ( Constants.itemWidth - 5, itemHeight - 5 )
            (model.items
                |> getAt 3
                |> Maybe.withDefault Item.emptyItem
            )

        -- Solution Ideas
        , Views.canvasView model.settings
            ( Constants.itemWidth, itemHeight * 2 )
            ( Constants.itemWidth * 2 - 10, 0 )
            (model.items
                |> getAt 1
                |> Maybe.withDefault Item.emptyItem
            )

        -- ️How will Users use Solution?
        , Views.canvasView model.settings
            ( Constants.itemWidth, itemHeight )
            ( Constants.itemWidth * 3 - 15, 0 )
            (model.items
                |> getAt 5
                |> Maybe.withDefault Item.emptyItem
            )

        -- Adoption Strategy
        , Views.canvasView model.settings
            ( Constants.itemWidth, itemHeight + 5 )
            ( Constants.itemWidth * 3 - 15, itemHeight - 5 )
            (model.items
                |> getAt 7
                |> Maybe.withDefault Item.emptyItem
            )

        -- User Metrics
        , Views.canvasView model.settings
            ( Constants.itemWidth, itemHeight * 2 )
            ( Constants.itemWidth * 4 - 20, 0 )
            (model.items
                |> getAt 6
                |> Maybe.withDefault Item.emptyItem
            )

        -- Business Challenges
        , Views.canvasView model.settings
            ( round (toFloat Constants.itemWidth * 2) - 5, itemHeight + 5 )
            ( 0, itemHeight * 2 - 5 )
            (model.items
                |> getAt 4
                |> Maybe.withDefault Item.emptyItem
            )

        -- Budget
        , Views.canvasView model.settings
            ( Constants.itemWidth, itemHeight + 5 )
            ( round (toFloat Constants.itemWidth * 2) - 10, itemHeight * 2 - 5 )
            (model.items
                |> getAt 9
                |> Maybe.withDefault Item.emptyItem
            )

        -- Business Benefits and Metrics
        , Views.canvasView model.settings
            ( round (toFloat Constants.itemWidth * 2) - 5, itemHeight + 5 )
            ( round (toFloat Constants.itemWidth * 3) - 15, itemHeight * 2 - 5 )
            (model.items
                |> getAt 8
                |> Maybe.withDefault Item.emptyItem
            )
        ]
