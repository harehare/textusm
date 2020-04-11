module Components.DiagramList exposing (init, update, view)

import Dict
import Dict.Extra as DictEx
import GraphQL.Models.DiagramItem as DiagramItem exposing (DiagramItem)
import GraphQL.Request as Request
import Html exposing (Html, div, img, input, span, text)
import Html.Attributes exposing (alt, class, placeholder, src, style)
import Html.Events exposing (onClick, onInput, stopPropagationOn)
import Html.Lazy exposing (lazy4)
import Json.Decode as D
import List.Extra exposing (updateIf)
import Maybe.Extra exposing (isJust)
import Models.DiagramList exposing (FilterCondition(..), FilterValue(..), Model, Msg(..))
import Models.DiagramType as DiagramType
import Models.User as UserModel exposing (User)
import Ports exposing (getDiagrams, removeDiagrams)
import RemoteData exposing (RemoteData(..))
import Task
import TextUSM.Enum.Diagram exposing (Diagram)
import Time exposing (Zone)
import Utils
import Views.Empty as Empty
import Views.Icon as Icon


pageSize : Int
pageSize =
    30


pageOffsetAndLimit : Int -> ( Int, Int )
pageOffsetAndLimit pageNo =
    ( pageSize * (pageNo - 1), pageSize * pageNo )


init : Maybe User -> String -> ( Model, Cmd Msg )
init user apiRoot =
    ( { searchQuery = Nothing
      , timeZone = Time.utc
      , diagramList = NotAsked
      , filterCondition = FilterCondition FilterAll (\_ -> True)
      , loginUser = user
      , apiRoot = apiRoot
      , pageNo = 1
      , hasMorePage = False
      }
    , Cmd.batch
        [ Task.perform GotTimeZone Time.here
        , getDiagrams ()
        ]
    )


facet : List DiagramItem -> List ( Diagram, Int )
facet items =
    DictEx.groupBy (\i -> DiagramType.toString i.diagram) items
        |> Dict.map (\k v -> ( k, List.length v ))
        |> Dict.values
        |> List.map (\( d, i ) -> ( DiagramType.fromString d, i ))


sideMenu : FilterValue -> Int -> Int -> List ( Diagram, Int ) -> Html Msg
sideMenu filter allCount bookmarkCount items =
    div [ class "side-menu" ]
        (div
            [ class <|
                if filter == FilterAll then
                    "item selected"

                else
                    "item"
            , onClick (Filter (FilterCondition FilterAll (\_ -> True)))
            ]
            [ text "All", span [ class "facet-count" ] [ text <| "(" ++ String.fromInt allCount ++ ")" ] ]
            :: div
                [ class <|
                    if filter == FilterBookmark then
                        "item selected"

                    else
                        "item"
                , onClick (Filter (FilterCondition FilterBookmark (\item -> item.isBookmark)))
                ]
                [ text "Bookmarks", span [ class "facet-count" ] [ text <| "(" ++ String.fromInt bookmarkCount ++ ")" ] ]
            :: (items
                    |> List.map
                        (\( diagram, count ) ->
                            div
                                [ class <|
                                    if filter == FilterValue diagram then
                                        "item selected"

                                    else
                                        "item"
                                , onClick (Filter (FilterCondition (FilterValue diagram) (\item -> item.diagram == diagram)))
                                ]
                                [ text <| DiagramType.toLongString diagram, span [ class "facet-count" ] [ text <| "(" ++ String.fromInt count ++ ")" ] ]
                        )
               )
        )


view : Model -> Html Msg
view model =
    case model.diagramList of
        Success diagrams ->
            let
                (FilterCondition selectedPath filterCondition) =
                    model.filterCondition

                displayDiagrams =
                    List.filter filterCondition diagrams
            in
            div
                [ class "diagram-list"
                , style "display" "flex"
                ]
                [ lazy4 sideMenu
                    selectedPath
                    (List.length diagrams)
                    (List.length (List.filter (\i -> i.isBookmark) diagrams))
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
                                [ Icon.search "#8C9FAE" 24 ]
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
                            , style "height" "calc(100% - 70px)"
                            , style "flex-wrap" "wrap"
                            , style "margin-bottom" "8px"
                            , style "align-content" "flex-start"
                            , style "overflow-y" "scroll"
                            , style "will-change" "transform"
                            , style "border-top" "1px solid #323B46"
                            ]
                            ((displayDiagrams
                                |> (case model.searchQuery of
                                        Just query ->
                                            List.filter (\d -> String.contains query d.title)

                                        Nothing ->
                                            identity
                                   )
                                |> List.map
                                    (\d -> diagramView model.timeZone d)
                             )
                                ++ [ if model.hasMorePage then
                                        div
                                            [ style "width" "100%"
                                            , style "display" "flex"
                                            , style "align-items" "center"
                                            , style "justify-content" "center"
                                            ]
                                            [ div
                                                [ class "primary-button button"
                                                , style "padding" "16px"
                                                , style "margin" "8px"
                                                , onClick <| LoadNextPage <| model.pageNo + 1
                                                ]
                                                [ text "Load more" ]
                                            ]

                                     else
                                        Empty.view
                                   ]
                            )
                    ]
                ]

        Failure e ->
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
                    [ div [ style "margin-bottom" "8px" ]
                        [ text ("FAILED " ++ Utils.httpErrorToString e)
                        ]
                    ]
                ]

        _ ->
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
                    [ div [ style "margin-bottom" "8px" ]
                        [ img [ src "/images/loading.svg", style "width" "64px", alt "LOADING..." ] []
                        ]
                    ]
                ]


diagramView : Zone -> DiagramItem -> Html Msg
diagramView timezone diagram =
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
                [ div [ style "margin-top" "4px" ] [ text (Utils.millisToString timezone diagram.updatedAt) ]
                , if diagram.isRemote then
                    div [ style "margin-left" "16px", class "cloud" ] [ Icon.cloudOn 14 ]

                  else
                    div [ style "margin-left" "16px", class "cloud" ] [ Icon.cloudOff 14 ]
                , div [ style "margin-left" "16px", class "button", stopPropagationOn "click" (D.succeed ( Remove diagram, True )) ] [ Icon.clear 18 ]
                , if diagram.isBookmark then
                    div
                        [ class "bookmark"
                        , stopPropagationOn "click" (D.succeed ( Bookmark diagram, True ))
                        ]
                        [ Icon.bookmark "#3e9bcd" 16 ]

                  else
                    div
                        [ class "bookmark"
                        , stopPropagationOn "click" (D.succeed ( Bookmark diagram, True ))
                        ]
                        [ Icon.unbookmark "#3e9bcd" 16 ]
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

        Filter cond ->
            ( { model | filterCondition = cond }, Cmd.none )

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

        LoadNextPage pageNo ->
            ( { model | pageNo = pageNo }, getDiagrams () )

        GotLocalDiagramJson json ->
            if model.diagramList == Loading then
                ( model, Cmd.none )

            else
                let
                    localItems =
                        Result.withDefault [] <|
                            D.decodeString (D.list DiagramItem.decoder) json
                in
                case model.loginUser of
                    Just _ ->
                        let
                            remoteItems =
                                Request.items { url = model.apiRoot, idToken = Maybe.map (\u -> UserModel.getIdToken u) model.loginUser } (pageOffsetAndLimit model.pageNo) False False
                                    |> Task.map
                                        (\i ->
                                            i
                                                |> List.filter (\item -> isJust item)
                                                |> List.map (\item -> Maybe.withDefault DiagramItem.empty item)
                                        )

                            items =
                                remoteItems
                                    |> Task.map
                                        (\item ->
                                            List.concat [ localItems, item ]
                                                |> List.sortWith
                                                    (\a b ->
                                                        let
                                                            v1 =
                                                                a.updatedAt |> Time.posixToMillis

                                                            v2 =
                                                                b.updatedAt |> Time.posixToMillis
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
                        ( { model
                            | diagramList =
                                if RemoteData.isNotAsked model.diagramList then
                                    Loading

                                else
                                    model.diagramList
                          }
                        , Task.attempt GotDiagrams items
                        )

                    Nothing ->
                        ( { model
                            | hasMorePage = False
                            , diagramList =
                                Success localItems
                          }
                        , Cmd.none
                        )

        GotDiagrams (Err ( items, _ )) ->
            ( { model
                | hasMorePage = List.length items >= pageSize
                , diagramList =
                    if RemoteData.isFailure model.diagramList then
                        Success items

                    else
                        RemoteData.andThen (\currentItems -> Success <| List.concat [ currentItems, items ]) model.diagramList
              }
            , Cmd.none
            )

        GotDiagrams (Ok items) ->
            ( { model
                | hasMorePage = List.length items >= pageSize
                , diagramList =
                    if List.isEmpty <| RemoteData.withDefault [] model.diagramList then
                        Success items

                    else
                        RemoteData.andThen (\currentItems -> Success <| List.concat [ currentItems, items ]) model.diagramList
              }
            , Cmd.none
            )

        Remove diagram ->
            ( model, removeDiagrams (DiagramItem.encoder diagram) )

        RemoveRemote diagramJson ->
            case D.decodeString DiagramItem.decoder diagramJson of
                Ok diagram ->
                    ( model
                    , Task.attempt Removed
                        (Request.delete { url = model.apiRoot, idToken = Maybe.map (\u -> UserModel.getIdToken u) model.loginUser } (Maybe.withDefault "" diagram.id)
                            |> Task.map (\_ -> Just diagram)
                        )
                    )

                Err _ ->
                    ( model
                    , Cmd.none
                    )

        Removed (Err _) ->
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

        Bookmark diagram ->
            let
                diagramList =
                    RemoteData.withDefault [] model.diagramList |> updateIf (\item -> item.id == diagram.id) (\item -> { item | isBookmark = not item.isBookmark })
            in
            ( { model | diagramList = Success diagramList }
            , Task.attempt Bookmarked
                (Request.bookmark { url = model.apiRoot, idToken = Maybe.map (\u -> UserModel.getIdToken u) model.loginUser } (Maybe.withDefault "" diagram.id) (not diagram.isBookmark)
                    |> Task.map (\_ -> Just diagram)
                )
            )

        _ ->
            ( model, Cmd.none )
