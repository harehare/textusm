module Views.DiagramList exposing (view)

import Dict
import Dict.Extra as DictEx
import Html exposing (Html, div, input, text)
import Html.Attributes exposing (class, placeholder, style)
import Html.Events exposing (onClick, onInput, stopPropagationOn)
import Json.Decode as D
import Maybe.Extra as MaybeEx
import Models.DiagramItem exposing (DiagramItem)
import Models.DiagramType exposing (DiagramType(..))
import Models.Model exposing (Msg(..))
import Models.User exposing (User)
import Time exposing (Zone)
import Utils
import Views.Empty as Empty
import Views.Icon as Icon


facet : List DiagramItem -> List ( String, Int )
facet items =
    items
        |> DictEx.groupBy .diagramPath
        |> Dict.map (\k v -> ( k, List.length v ))
        |> Dict.values


sideMenu : String -> Int -> List ( String, Int ) -> Html Msg
sideMenu selectedPath allCount items =
    div [ class "side-menu" ]
        (div
            [ class <|
                if String.isEmpty selectedPath then
                    "item selected"

                else
                    "item"
            , onClick (FilterDiagramList Nothing)
            ]
            [ text <| "All(" ++ String.fromInt allCount ++ ")" ]
            :: (items
                    |> List.map
                        (\( diagramPath, count ) ->
                            div
                                [ class <|
                                    if selectedPath == diagramPath then
                                        "item selected"

                                    else
                                        "item"
                                , onClick (FilterDiagramList <| Just diagramPath)
                                ]
                                [ text <| menuName diagramPath ++ "(" ++ String.fromInt count ++ ")" ]
                        )
               )
        )


menuName : String -> String
menuName path =
    case path of
        "usm" ->
            "User Story Map"

        "opc" ->
            "Opportunity Canvas"

        "bmc" ->
            "Business Model Canvas"

        "4ls" ->
            "4Ls"

        "ssc" ->
            "Start, Stop, Continue"

        "kpt" ->
            "KPT"

        "persona" ->
            "User Persona"

        "md" ->
            "Markdown"

        "" ->
            "All"

        _ ->
            "User Story Map"


view : Maybe User -> Zone -> Maybe String -> Maybe (List DiagramItem) -> Maybe String -> Html Msg
view user timezone maybeQuery maybeDiagrams selectedType =
    case maybeDiagrams of
        Just diagrams ->
            let
                displayDiagrams =
                    case selectedType of
                        Just type_ ->
                            List.filter (\d -> d.diagramPath == type_) diagrams

                        Nothing ->
                            diagrams
            in
            div
                [ class "diagram-list"
                , style "display" "flex"
                ]
                [ sideMenu (Maybe.withDefault "" selectedType)
                    (List.length diagrams)
                    (facet diagrams)
                , div
                    [ style "width" "100%" ]
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
                    , if List.isEmpty displayDiagrams then
                        div
                            [ style "display" "flex"
                            , style "align-items" "center"
                            , style "justify-content" "center"
                            , style "height" "100%"
                            , style "color" "#8C9FAE"
                            , style "font-size" "1.5rem"
                            , style "padding-bottom" "32px"
                            ]
                            [ div [ style "margin-right" "8px" ] [ Icon.viewComfy "#8C9FAE" 64 ]
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
                            (displayDiagrams
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
                ]

        Nothing ->
            div
                [ class "diagram-list"
                , style "width" "100vw"
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
                    , style "padding-bottom" "32px"
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
                    Empty.view
                ]
            ]
        ]
