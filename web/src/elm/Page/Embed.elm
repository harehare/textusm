module Page.Embed exposing (..)

import Components.Diagram as Diagram
import Html exposing (Html, div)
import Html.Attributes exposing (class, style)
import Html.Lazy as Lazy
import Models.Model exposing (Model, Msg(..))
import Views.Logo as Logo


view : Model -> Html Msg
view model =
    div
        [ style "border" "1px solid var(--dark-text-color)"
        , style "background-color" model.settingsModel.settings.storyMap.backgroundColor
        , class "full relative"
        ]
        [ Lazy.lazy Diagram.view model.diagramModel
            |> Html.map UpdateDiagram
        , div [ class "absolute", style "bottom" "8px", style "right" "8px" ] [ Logo.view ]
        ]
