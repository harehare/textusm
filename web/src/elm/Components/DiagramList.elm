module Components.DiagramList exposing (init, update, view)

import Api.Diagram as DiagramApi
import Dict
import Dict.Extra as DictEx
import Html exposing (Html, div, input, span, text)
import Html.Attributes exposing (class, placeholder, style)
import Html.Events exposing (onClick, onInput, stopPropagationOn)
import Json.Decode as D
import Maybe.Extra as MaybeEx
import Models.DiagramItem exposing (DiagramItem)
import Models.DiagramList exposing (..)
import Models.DiagramType exposing (DiagramType(..))
import Models.User as UserModel exposing (User)
import Subscriptions exposing (getDiagrams, removeDiagrams)
import Task
import Time exposing (Zone)
import Utils
import Views.Empty as Empty
import Views.Icon as Icon


init : Maybe User -> String -> ( Model, Cmd Msg )
init user apiRoot =
    ( { searchQuery = Nothing
      , timeZone = Time.utc
      , diagramList = Nothing
      , selectedType = Nothing
      , loginUser = user
      , apiRoot = apiRoot
      }
    , Cmd.batch
        [ Task.perform GotTimeZone Time.here
        , getDiagrams ()
        ]
    )


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
            , onClick (Filter Nothing)
            ]
            [ text "All", span [ class "facet-count" ] [ text <| "(" ++ String.fromInt allCount ++ ")" ] ]
            :: (items
                    |> List.map
                        (\( diagramPath, count ) ->
                            div
                                [ class <|
                                    if selectedPath == diagramPath then
                                        "item selected"

                                    else
                                        "item"
                                , onClick (Filter <| Just diagramPath)
                                ]
                                [ text <| menuName diagramPath, span [ class "facet-count" ] [ text <| "(" ++ String.fromInt count ++ ")" ] ]
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

        "mmp" ->
            "Mind Map"

        "emm" ->
            "Empathy Map"

        "cjm" ->
            "Customer Journey Map"

        "smp" ->
            "Site Map"

        "gct" ->
            "Gantt Chart"

        "" ->
            "All"

        _ ->
            "User Story Map"


view : Model -> Html Msg
view model =
    case model.diagramList of
        Just diagrams ->
            let
                displayDiagrams =
                    case model.selectedType of
                        Just type_ ->
                            List.filter (\d -> d.diagramPath == type_) diagrams

                        Nothing ->
                            diagrams
            in
            div
                [ class "diagram-list"
                , style "display" "flex"
                ]
                [ sideMenu (Maybe.withDefault "" model.selectedType)
                    (List.length diagrams)
                    (facet diagrams)
                , div
                    [ style "width" "100%" ]
                    [ div
                        [ style "padding" "16px"
                        , style "display" "flex"
                        , style "align-items" "center"
                        , style "justify-content" "flex-end"
                        , style "font-weight" "400"
                        , style "color" "#FEFEFE"
                        ]
                        [ div
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
                                , onInput SearchInput
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
                                |> (case model.searchQuery of
                                        Just query ->
                                            List.filter (\d -> String.contains query d.title)

                                        Nothing ->
                                            identity
                                   )
                                |> List.map
                                    (\d -> diagramView model.loginUser model.timeZone d)
                            )
                    ]
                ]

        Nothing ->
            div
                [ class "diagram-list"
                , style "width" "100vw"
                ]
                [ div
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
        , stopPropagationOn "click" (D.succeed ( Select diagram, True ))
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
                    div [ style "margin-left" "16px", class "button", stopPropagationOn "click" (D.succeed ( Remove diagram, True )) ] [ Icon.clear 18 ]

                  else
                    Empty.view
                ]
            ]
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        NoOp ->
            ( model, Cmd.none )

        GotTimeZone zone ->
            ( { model | timeZone = zone }, Cmd.none )

        Filter type_ ->
            ( { model | selectedType = type_ }, Cmd.none )

        SearchInput input ->
            ( { model
                | searchQuery =
                    if String.isEmpty input then
                        Nothing

                    else
                        Just input
              }
            , Cmd.none
            )

        GotLocalDiagrams localItems ->
            case model.loginUser of
                Just _ ->
                    let
                        remoteItems =
                            DiagramApi.items (Maybe.map (\u -> UserModel.getIdToken u) model.loginUser) 1 model.apiRoot

                        items =
                            remoteItems
                                |> Task.map
                                    (\item ->
                                        List.concat [ localItems, item ]
                                            |> List.sortWith
                                                (\a b ->
                                                    let
                                                        v1 =
                                                            a.updatedAt |> Maybe.withDefault 0

                                                        v2 =
                                                            b.updatedAt |> Maybe.withDefault 0
                                                    in
                                                    if v1 - v2 > 0 then
                                                        LT

                                                    else if v1 - v2 < 0 then
                                                        GT

                                                    else
                                                        EQ
                                                )
                                    )
                                |> Task.mapError (Tuple.pair localItems)
                    in
                    ( model, Task.attempt GotDiagrams items )

                Nothing ->
                    ( { model | diagramList = Just localItems }, Cmd.none )

        GotDiagrams (Err ( items, _ )) ->
            ( { model | diagramList = Just items }, Cmd.none )

        GotDiagrams (Ok items) ->
            ( { model | diagramList = Just items }, Cmd.none )

        Remove diagram ->
            ( model, removeDiagrams diagram )

        RemoveRemote diagram ->
            ( model
            , Task.attempt Removed
                (DiagramApi.remove (Utils.getIdToken model.loginUser) model.apiRoot (diagram.id |> Maybe.withDefault "")
                    |> Task.mapError (Tuple.pair diagram)
                    |> Task.map (\_ -> diagram)
                )
            )

        Removed (Err ( _, _ )) ->
            ( model
            , Cmd.none
            )

        Removed (Ok _) ->
            ( model
            , getDiagrams ()
            )

        Reload ->
            ( model
            , getDiagrams ()
            )

        _ ->
            ( model, Cmd.none )
