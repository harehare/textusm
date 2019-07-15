module Views.DiagramList exposing (view)

import Html exposing (Html, div, input, text)
import Html.Attributes exposing (class, placeholder, style)
import Html.Events exposing (onInput, stopPropagationOn)
import Json.Decode as D
import Maybe.Extra as MaybeEx
import Models.DiagramItem exposing (DiagramItem)
import Models.Model exposing (Msg(..))
import Models.User exposing (User)
import Time exposing (Zone)
import Utils
import Views.Icon as Icon


view : Maybe User -> Zone -> Maybe String -> Maybe (List DiagramItem) -> Html Msg
view user timezone maybeQuery maybeDiagrams =
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
                    , div
                        [ style "display" "flex"
                        , style "align-items" "center"
                        ]
                        [ div
                            [ style "position" "absolute"
                            , style "right" "20px"
                            , style "top" "18px"
                            ]
                            [ Icon.search 24 ]
                        , input
                            [ placeholder "Search"
                            , style "border-radius" "20px"
                            , style "padding" "8px"
                            , style "border" "none"
                            , onInput Search
                            ]
                            []
                        ]
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
                        (diagrams
                            |> (case maybeQuery of
                                    Just query ->
                                        List.filter (\d -> String.contains query d.title)

                                    Nothing ->
                                        identity
                               )
                            |> List.map
                                (\d -> diagramView user timezone d)
                        )
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


diagramView : Maybe User -> Zone -> DiagramItem -> Html Msg
diagramView user timezone diagram =
    let
        isOwner =
            user
                |> Maybe.map (\u -> u.id == (diagram.ownerId |> Maybe.withDefault ""))
                |> Maybe.withDefault False
    in
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
                , if MaybeEx.isNothing user || MaybeEx.isNothing diagram.ownerId || isOwner then
                    div [ style "margin-left" "16px", class "button", stopPropagationOn "click" (D.succeed ( RemoveDiagram diagram, True )) ] [ Icon.clear 18 ]

                  else
                    div [] []
                ]
            ]
        ]
