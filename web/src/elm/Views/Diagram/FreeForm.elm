module Views.Diagram.FreeForm exposing (..)

import Models.Diagram as Diagram exposing (Model, Msg(..))
import Svg exposing (Svg, g)


view : Model -> Svg Msg
view model =
    g [] []
