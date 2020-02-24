module Views.Diagram.UserPersona exposing (view)

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
            model.selectedItem
            (model.items
                |> getAt 1
                |> Maybe.withDefault Item.emptyItem
            )

        -- three reasons to use your product
        , Views.canvasView model.settings
            ( round (toFloat Constants.itemWidth * 1.5 - 5), itemHeight )
            ( round (toFloat Constants.itemWidth * 2) - 10, 0 )
            model.selectedItem
            (model.items
                |> getAt 2
                |> Maybe.withDefault Item.emptyItem
            )

        -- three reasons to buy your product
        , Views.canvasView model.settings
            ( round (toFloat Constants.itemWidth * 1.5), itemHeight )
            ( round (toFloat Constants.itemWidth * 3.5) - 20, 0 )
            model.selectedItem
            (model.items
                |> getAt 3
                |> Maybe.withDefault Item.emptyItem
            )

        -- My interests
        , Views.canvasView model.settings
            ( Constants.itemWidth, itemHeight )
            ( 0, itemHeight - 5 )
            model.selectedItem
            (model.items
                |> getAt 4
                |> Maybe.withDefault Item.emptyItem
            )

        -- My personality
        , Views.canvasView model.settings
            ( Constants.itemWidth, itemHeight )
            ( Constants.itemWidth - 5, itemHeight - 5 )
            model.selectedItem
            (model.items
                |> getAt 5
                |> Maybe.withDefault Item.emptyItem
            )

        -- My skils
        , Views.canvasView model.settings
            ( Constants.itemWidth, itemHeight )
            ( Constants.itemWidth * 2 - 10, itemHeight - 5 )
            model.selectedItem
            (model.items
                |> getAt 6
                |> Maybe.withDefault Item.emptyItem
            )

        -- My dreams
        , Views.canvasView model.settings
            ( Constants.itemWidth, itemHeight )
            ( Constants.itemWidth * 3 - 15, itemHeight - 5 )
            model.selectedItem
            (model.items
                |> getAt 7
                |> Maybe.withDefault Item.emptyItem
            )

        -- My relationship with technology
        , Views.canvasView model.settings
            ( Constants.itemWidth, itemHeight )
            ( Constants.itemWidth * 4 - 20, itemHeight - 5 )
            model.selectedItem
            (model.items
                |> getAt 8
                |> Maybe.withDefault Item.emptyItem
            )
        ]
