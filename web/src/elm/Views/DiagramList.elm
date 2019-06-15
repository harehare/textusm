module Views.DiagramList exposing (view)

import Html exposing (Html, div, img, text)
import Html.Attributes exposing (class, id, src, style)
import Html.Events exposing (onClick, stopPropagationOn)
import Json.Decode as D
import Models.Model exposing (Diagram, Msg(..))
import Styles
import Subscriptions exposing (encodeShareText)
import Time exposing (Zone, millisToPosix, toDay, toMonth, toYear)
import Utils
import Views.Icon as Icon


view : Zone -> List Diagram -> Html Msg
view timezone diagrams =
    div
        [ class "diagram-list"
        ]
        [ div
            [ style "padding" "16px"
            , style "display" "flex"
            , style "align-items" "center"
            , style "justify-content" "space-between"
            , style "font-weight" "400"
            , style "color" "#FEFEFE"
            ]
            [ div
                [ style "font-weight" "400"
                ]
                [ text "MY DIAGRAMS" ]
            ]
        , if List.isEmpty diagrams then
            div
                [ style "display" "flex"
                , style "align-items" "center"
                , style "justify-content" "center"
                , style "height" "100%"
                , style "color" "#8C9FAE"
                , style "font-size" "2.0rem"
                ]
                [ div [ style "margin-right" "8px" ] [ Icon.viewComfy 64 ]
                , div [ style "margin-bottom" "8px" ] [ text "NOTHING" ]
                ]

          else
            div
                [ style "display" "flex"
                , style "align-items" "flex-start"
                , style "justify-content" "flex-start"
                , style "height" "calc(100vh - 70px)"
                , style "flex-wrap" "wrap"
                , style "margin-bottom" "8px"
                , style "align-content" "flex-start"
                , style "overflow" "scroll"
                , style "will-change" "transform"
                , style "border-top" "1px solid #323B46"
                ]
                (List.map (\d -> diagramView timezone d) diagrams)
        ]


diagramView : Zone -> Diagram -> Html Msg
diagramView timezone diagram =
    div
        [ class "diagram-item"
        , style "background-image" ("url(\"" ++ (diagram.thumbnail |> Maybe.withDefault "") ++ "\")")
        , stopPropagationOn "click" (D.succeed ( OpenDiagram diagram, True ))
        ]
        [ div
            [ class "diagram-text"
            ]
            [ div
                [ style "overflow" "hidden"
                , style "text-overflow" "ellipsis"
                ]
                [ text diagram.title ]
            , div
                [ style "display" "flex"
                , style "align-items" "center"
                , style "justify-content" "space-between"
                , style "margin-top" "8px"
                ]
                [ div [ style "margin-top" "4px" ] [ text (Utils.millisToString timezone (diagram.updatedAt |> Maybe.withDefault 0)) ]
                , div [ style "margin-left" "8px", class "button", stopPropagationOn "click" (D.succeed ( RemoveDiagram diagram, True )) ] [ Icon.clear 20 ]
                ]
            ]
        ]
