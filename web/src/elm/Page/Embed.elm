module Page.Embed exposing (..)

import Components.Diagram as Diagram
import Data.Size exposing (Size)
import Html exposing (Html, div)
import Html.Attributes exposing (style)
import Html.Lazy as Lazy
import Models.Model exposing (Model, Msg(..))


view : Model -> Html Msg
view model =
    div
        [ style "width" "100%"
        , style "height" "100%"
        , style "border" "1px solid var(--dark-text-color)"
        , style "background-color" model.settingsModel.settings.storyMap.backgroundColor
        ]
        [ Lazy.lazy Diagram.view model.diagramModel
            |> Html.map UpdateDiagram
        ]
