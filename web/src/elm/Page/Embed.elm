module Page.Embed exposing (view)

import Components.Diagram as Diagram
import Css
    exposing
        ( absolute
        , backgroundColor
        , border3
        , bottom
        , hex
        , position
        , px
        , relative
        , right
        , solid
        )
import Html.Styled as Html exposing (Html, div)
import Html.Styled.Attributes as Attr
import Html.Styled.Lazy as Lazy
import Models.Model exposing (Model, Msg(..))
import Style.Color as Color
import Style.Style as Style
import Views.Logo as Logo


view : Model -> Html Msg
view model =
    div
        [ Attr.css
            [ border3 (px 1) solid Color.darkTextColor
            , backgroundColor <| hex model.settingsModel.settings.storyMap.backgroundColor
            , Style.full
            , position relative
            ]
        ]
        [ Lazy.lazy Diagram.view model.diagramModel
            |> Html.map UpdateDiagram
        , div [ Attr.css [ position absolute, bottom <| px 8, right <| px 8 ] ] [ Logo.view ]
        ]
