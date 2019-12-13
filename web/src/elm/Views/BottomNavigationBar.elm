module Views.BottomNavigationBar exposing (view)

import Html exposing (Html, a, div, img, text)
import Html.Attributes exposing (alt, class, href, id, src, style, target)
import Html.Events exposing (onClick)
import Models.Diagram as DiagramModel
import Models.Model exposing (Msg(..))
import Models.Settings exposing (Settings)
import Route exposing (Route(..))
import Styles
import Views.Icon as Icon


view : Settings -> String -> String -> String -> Html Msg
view settings diagram title path =
    div
        [ class "bottom-nav-bar"
        , style "background-color" settings.storyMap.backgroundColor
        ]
        [ div
            [ style "display" "flex"
            , style "align-items" "center"
            ]
            [ logo
            , a [ href <| "https://app.textusm.com/share/" ++ diagram ++ "/" ++ title ++ "/" ++ path, target "blank_", style "color" settings.storyMap.color.label ]
                [ text title ]
            ]
        , div [ class "buttons" ]
            [ div
                [ class "button"
                , onClick <| UpdateDiagram DiagramModel.ZoomIn
                ]
                [ Icon.add 32 ]
            , div
                [ class "button"
                , onClick <| UpdateDiagram DiagramModel.ZoomOut
                ]
                [ Icon.remove 32 ]
            , div
                [ class "button"
                , onClick <| UpdateDiagram DiagramModel.ToggleFullscreen
                ]
                [ Icon.fullscreen 32 ]
            ]
        ]


logo : Html Msg
logo =
    div
        [ style "width"
            "40px"
        , style "height"
            "40px"
        , style "display" "flex"
        , style "justify-content" "center"
        , style "align-items" "center"
        ]
        [ a [ href "https://app.textusm.com", target "blank_" ]
            [ img [ src "/images/logo.svg", style "width" "32px", alt "logo" ] [] ]
        ]
