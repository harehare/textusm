module Views.Diagram.MiniMap exposing (..)

import Models.Diagram exposing (Model, Msg(..))
import Models.Views.FourLs exposing (FourLsItem(..))
import Svg exposing (Svg, g)


view : Model -> Svg Msg
view model =
    g [] [ g [] [] ]
