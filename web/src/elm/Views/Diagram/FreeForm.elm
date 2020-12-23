module Views.Diagram.FreeForm exposing (..)

import Models.Diagram as Diagram exposing (Model, Msg(..))
import Svg exposing (Svg)


view : Model -> Svg Msg
view model =
    Svg.g [] []
