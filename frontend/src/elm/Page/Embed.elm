module Page.Embed exposing (view)

import Css
import Diagram.View as Diagram
import Html.Styled as Html exposing (Html, div)
import Html.Styled.Attributes as Attr
import Html.Styled.Lazy as Lazy
import Style.Color as Color
import Style.Style as Style
import Types exposing (Model, Msg(..))
import Types.Color as Color
import View.Logo as Logo


view : Model -> Html Msg
view model =
    div
        [ Attr.css
            [ Css.border3 (Css.px 1) Css.solid Color.darkTextColor
            , Css.backgroundColor <| Css.hex <| Color.toString model.settingsModel.settings.diagramSettings.backgroundColor
            , Style.full
            , Css.position Css.relative
            ]
        ]
        [ Lazy.lazy Diagram.view model.diagramModel
            |> Html.map UpdateDiagram
        , div [ Attr.css [ Css.position Css.absolute, Css.bottom <| Css.px 8, Css.right <| Css.px 8 ] ] [ Logo.view ]
        ]
