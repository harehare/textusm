module Views.Diagram.BusinessModelCanvas exposing (view)

import Constants
import List.Extra exposing (getAt)
import Models.Diagram exposing (Model, Msg(..))
import Models.Item as Item exposing (ItemType(..))
import String
import Svg exposing (Svg, g)
import Svg.Attributes exposing (fill, transform)
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
        [ -- Key Partners
          Views.canvasView model.settings
            ( Constants.itemWidth, itemHeight * 2 )
            ( 0, 0 )
            (model.items
                |> getAt 0
                |> Maybe.withDefault Item.emptyItem
            )

        -- Key Activities
        , Views.canvasView model.settings
            ( Constants.itemWidth, itemHeight )
            ( Constants.itemWidth - 5, 0 )
            (model.items
                |> getAt 3
                |> Maybe.withDefault Item.emptyItem
            )

        -- Key Resources
        , Views.canvasView model.settings
            ( Constants.itemWidth, itemHeight + 5 )
            ( Constants.itemWidth - 5, itemHeight - 5 )
            (model.items
                |> getAt 7
                |> Maybe.withDefault Item.emptyItem
            )

        -- Value Propotion
        , Views.canvasView model.settings
            ( Constants.itemWidth, itemHeight * 2 )
            ( Constants.itemWidth * 2 - 10, 0 )
            (model.items
                |> getAt 2
                |> Maybe.withDefault Item.emptyItem
            )

        -- ️Customer Relationships
        , Views.canvasView model.settings
            ( Constants.itemWidth, itemHeight )
            ( Constants.itemWidth * 3 - 15, 0 )
            (model.items
                |> getAt 8
                |> Maybe.withDefault Item.emptyItem
            )

        -- Channels
        , Views.canvasView model.settings
            ( Constants.itemWidth, itemHeight + 5 )
            ( Constants.itemWidth * 3 - 15, itemHeight - 5 )
            (model.items
                |> getAt 4
                |> Maybe.withDefault Item.emptyItem
            )

        -- Customer Segments
        , Views.canvasView model.settings
            ( Constants.itemWidth, itemHeight * 2 )
            ( Constants.itemWidth * 4 - 20, 0 )
            (model.items
                |> getAt 1
                |> Maybe.withDefault Item.emptyItem
            )

        -- Cost Structure
        , Views.canvasView model.settings
            ( round (toFloat Constants.itemWidth * 2.5) - 10, itemHeight + 5 )
            ( 0, itemHeight * 2 - 5 )
            (model.items
                |> getAt 6
                |> Maybe.withDefault Item.emptyItem
            )

        -- Revenue Streams
        , Views.canvasView model.settings
            ( round (toFloat Constants.itemWidth * 2.5) - 5, itemHeight + 5 )
            ( round (toFloat Constants.itemWidth * 2.5) - 15, itemHeight * 2 - 5 )
            (model.items
                |> getAt 5
                |> Maybe.withDefault Item.emptyItem
            )
        ]
