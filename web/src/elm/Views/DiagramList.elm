module Views.DiagramList exposing (view)

import Html exposing (Html, div, text)
import Html.Attributes exposing (class, style)
import Html.Events exposing (stopPropagationOn)
import Json.Decode as D
import Models.DiagramItem exposing (DiagramItem)
import Models.Model exposing (Msg(..))
import Time exposing (Zone)
import Utils
import Views.Icon as Icon


view : Zone -> Maybe (List DiagramItem) -> Html Msg
view timezone maybeDiagrams =
    case maybeDiagrams of
        Just diagrams ->
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
                        , style "font-size" "1.5rem"
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

        Nothing ->
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
                , div
                    [ style "display" "flex"
                    , style "align-items" "center"
                    , style "justify-content" "center"
                    , style "height" "100%"
                    , style "color" "#8C9FAE"
                    , style "font-size" "1.5rem"
                    ]
                    [ div [ style "margin-bottom" "8px" ] [ text "LOADING..." ]
                    ]
                ]


diagramView : Zone -> DiagramItem -> Html Msg
diagramView timezone diagram =
    div
        [ class "diagram-item"
        , style "background-image" ("url(\"" ++ (diagram.thumbnail |> Maybe.withDefault "") ++ "\")")
        , stopPropagationOn "click" (D.succeed ( Open diagram, True ))
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
                , if diagram.isRemote then
                    div [ style "margin-left" "16px", class "cloud" ] [ Icon.cloudOn 14 ]

                  else
                    div [ style "margin-left" "16px", class "cloud" ] [ Icon.cloudOff 14 ]
                , div [ style "margin-left" "16px", class "button", stopPropagationOn "click" (D.succeed ( RemoveDiagram diagram, True )) ] [ Icon.clear 20 ]
                ]
            ]
        ]
