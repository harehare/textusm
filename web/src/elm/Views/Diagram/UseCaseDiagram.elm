module Views.Diagram.UseCaseDiagram exposing (view)

import Data.Position exposing (Position)
import Models.Diagram as Diagram exposing (Model, Msg(..))
import Models.Views.Kpt exposing (KptItem(..))
import Svg exposing (Svg)
import Svg.Lazy as Lazy
import Utils.Diagram as DiagramUtils
import Views.Diagram.Views as Views
import Views.Empty as Empty


view : Model -> Svg Msg
view model =
    case model.data of
        Diagram.UseCaseDiagram u ->
            Svg.g [] []

        _ ->
            Empty.view


actorView : String -> Position -> Svg Msg
actorView name ( x, y ) =
    Svg.g [] []
