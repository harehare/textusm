port module Page.List exposing (Model, Msg(..), init, update, view)

import Data.DiagramType as DiagramType
import Data.Session as Session exposing (Session)
import Dict
import Dict.Extra as DictEx
import GraphQL.Models.DiagramItem as DiagramItem exposing (DiagramItem)
import GraphQL.Request as Request
import Graphql.Http as Http
import Html exposing (Html, div, img, input, span, text)
import Html.Attributes exposing (alt, class, placeholder, src, style)
import Html.Events exposing (onClick, onInput, stopPropagationOn)
import Html.Lazy exposing (lazy2, lazy5)
import Json.Decode as D
import Json.Encode as E
import List.Extra exposing (updateIf)
import Maybe.Extra exposing (isJust)
import RemoteData exposing (RemoteData(..), WebData)
import Set
import Task
import TextUSM.Enum.Diagram exposing (Diagram)
import Time exposing (Zone)
import Utils
import Views.Empty as Empty
import Views.Icon as Icon


type Msg
    = NoOp
    | Filter FilterCondition
    | SearchInput String
    | Select DiagramItem
    | Reload
    | Remove DiagramItem
    | Bookmark DiagramItem
    | RemoveRemote String
    | Removed (Result (Http.Error (Maybe DiagramItem)) (Maybe DiagramItem))
    | Bookmarked (Result (Http.Error (Maybe DiagramItem)) (Maybe DiagramItem))
    | GotTimeZone Zone
    | GotLocalDiagramJson String
    | GotDiagrams (Result ( List DiagramItem, Http.Error (List (Maybe DiagramItem)) ) (List DiagramItem))
    | LoadNextPage Int


type FilterValue
    = FilterAll
    | FilterBookmark
    | FilterValue Diagram
    | FilterTag String


type FilterCondition
    = FilterCondition FilterValue (DiagramItem -> Bool)


type alias Model =
    { searchQuery : Maybe String
    , timeZone : Zone
    , diagramList : WebData (List DiagramItem)
    , filterCondition : FilterCondition
    , session : Session
    , apiRoot : String
    , pageNo : Int
    , hasMorePage : Bool
    }


pageSize : Int
pageSize =
    30


pageOffsetAndLimit : Int -> ( Int, Int )
pageOffsetAndLimit pageNo =
    ( pageSize * (pageNo - 1), pageSize * pageNo )


port getDiagrams : () -> Cmd msg


port removeDiagrams : E.Value -> Cmd msg


init : Session -> String -> ( Model, Cmd Msg )
init session apiRoot =
    ( { searchQuery = Nothing
      , timeZone = Time.utc
      , diagramList = NotAsked
      , filterCondition = FilterCondition FilterAll (\_ -> True)
      , session = session
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


tags : List DiagramItem -> List String
tags items =
    List.map
        (\item ->
            item.tags
                |> Maybe.withDefault []
                |> List.map (Maybe.withDefault "")
                |> List.filter (String.isEmpty >> not)
        )
        items
        |> List.concat
        |> Set.fromList
        |> Set.toList


sideMenu : FilterValue -> Int -> Int -> List ( Diagram, Int ) -> List String -> Html Msg
sideMenu filter allCount bookmarkCount diagramItems tagItems =
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
            :: (diagramItems
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
            ++ (tagItems
                    |> List.map
                        (\tag ->
                            div
                                [ class <|
                                    if filter == FilterTag tag then
                                        "item selected"

                                    else
                                        "item"
                                , onClick
                                    (Filter
                                        (FilterCondition (FilterTag tag)
                                            (\item ->
                                                List.member tag
                                                    (item.tags
                                                        |> Maybe.withDefault []
                                                        |> List.map (Maybe.withDefault "")
                                                    )
                                            )
                                        )
                                    )
                                ]
                                [ text tag ]
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
                [ lazy5 sideMenu
                    selectedPath
                    (List.length diagrams)
                    (List.length (List.filter (\i -> i.isBookmark) diagrams))
                    (facet diagrams)
                    (tags diagrams)
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
                            , style "width" "100%"
                            ]
                            [ div
                                [ style "position" "absolute"
                                , style "right" "20px"
                                , style "top" "18px"
                                ]
                                [ Icon.search "#8C9FAE" 24 ]
                            , input
                                [ placeholder "Search"
                                , style "border-radius" "16px"
                                , style "padding" "8px"
                                , style "border" "none"
                                , style "width" "100%"
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
                            [ div [ style "margin-bottom" "8px" ] [ text "NOTHING" ]
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
                            , style "padding" "8px"
                            ]
                            ((displayDiagrams
                                |> (case model.searchQuery of
                                        Just query ->
                                            List.filter (\d -> String.contains query d.title)

                                        Nothing ->
                                            identity
                                   )
                                |> List.map
                                    (\d -> lazy2 diagramView model.timeZone d)
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
                [ div [] [ text (Utils.millisToString timezone diagram.updatedAt) ]
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
                , div [ class "diagram-tags" ] (List.map tagView (diagram.tags |> Maybe.withDefault [] |> List.map (Maybe.withDefault "")))
                ]
            ]
        ]


tagView : String -> Html Msg
tagView tag =
    div [ class "diagram-tag" ] [ text tag ]


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
                if Session.isSignedIn model.session then
                    let
                        remoteItems =
                            Request.items { url = model.apiRoot, idToken = Session.getIdToken model.session } (pageOffsetAndLimit model.pageNo) False False
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

                else
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
                        (Request.delete { url = model.apiRoot, idToken = Session.getIdToken model.session } (Maybe.withDefault "" diagram.id)
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
                (Request.bookmark { url = model.apiRoot, idToken = Session.getIdToken model.session } (Maybe.withDefault "" diagram.id) (not diagram.isBookmark)
                    |> Task.map (\_ -> Just diagram)
                )
            )

        _ ->
            ( model, Cmd.none )
