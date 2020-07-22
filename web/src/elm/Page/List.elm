port module Page.List exposing (Model, Msg(..), init, update, view)

import Asset
import Data.DiagramId as DiagramId
import Data.DiagramItem as DiagramItem exposing (DiagramItem)
import Data.Session as Session exposing (Session)
import File exposing (File)
import File.Download as Download
import File.Select as Select
import GraphQL.Request as Request
import Graphql.Http as Http
import Html exposing (Html, div, img, input, span, text)
import Html.Attributes exposing (alt, class, placeholder, src, style)
import Html.Events exposing (onClick, onInput, stopPropagationOn)
import Html.Lazy as Lazy
import Json.Decode as D
import Json.Encode as E
import List.Extra exposing (unique, updateIf)
import Maybe.Extra exposing (isJust)
import RemoteData exposing (RemoteData(..), WebData)
import Task
import Time exposing (Zone)
import Translations exposing (Lang)
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
    | RemoveRemote D.Value
    | Removed (Result (Http.Error (Maybe DiagramItem)) (Maybe DiagramItem))
    | Bookmarked (Result (Http.Error (Maybe DiagramItem)) (Maybe DiagramItem))
    | GotTimeZone Zone
    | GotLocalDiagramsJson D.Value
    | GotDiagrams (Result ( List DiagramItem, Http.Error (List (Maybe DiagramItem)) ) (List DiagramItem))
    | LoadNextPage Int
    | Export
    | Import
    | ImportFile File
    | ImportComplete String


type FilterValue
    = FilterAll
    | FilterBookmark
    | FilterPublic
    | FilterTag String


type FilterCondition
    = FilterCondition FilterValue (DiagramItem -> Bool)


type alias Model =
    { searchQuery : Maybe String
    , timeZone : Zone
    , diagramList : WebData (List DiagramItem)
    , publicDiagramList : WebData (List DiagramItem)
    , filterCondition : FilterCondition
    , session : Session
    , apiRoot : String
    , pageNo : Int
    , hasMorePage : Bool
    , lang : Lang
    }


pageSize : Int
pageSize =
    30


pageOffsetAndLimit : Int -> ( Int, Int )
pageOffsetAndLimit pageNo =
    ( pageSize * (pageNo - 1), pageSize * pageNo )


port getDiagrams : () -> Cmd msg


port removeDiagrams : E.Value -> Cmd msg


port importDiagram : E.Value -> Cmd msg


init : Session -> Lang -> String -> ( Model, Cmd Msg )
init session lang apiRoot =
    ( { searchQuery = Nothing
      , timeZone = Time.utc
      , diagramList = NotAsked
      , publicDiagramList = NotAsked
      , filterCondition = FilterCondition FilterAll (\_ -> True)
      , session = session
      , apiRoot = apiRoot
      , pageNo = 1
      , hasMorePage = False
      , lang = lang
      }
    , Cmd.batch
        [ Task.perform GotTimeZone Time.here
        , getDiagrams ()
        ]
    )


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
        |> unique


sideMenu : Session -> FilterValue -> List String -> Html Msg
sideMenu session filter tagItems =
    div [ class "side-menu" ]
        (div
            [ class <|
                if filter == FilterAll then
                    "item selected"

                else
                    "item"
            , onClick <| Filter (FilterCondition FilterAll (\_ -> True))
            ]
            [ text "All" ]
            :: (if Session.isSignedIn session then
                    div
                        [ class <|
                            if filter == FilterPublic then
                                "item selected"

                            else
                                "item"
                        ]
                        [ Icon.globe "#F5F5F6" 16, div [ style "padding" "8px" ] [ text "Public" ] ]

                else
                    div [] []
               )
            :: div
                [ class <|
                    if filter == FilterBookmark then
                        "item selected"

                    else
                        "item"
                , onClick <| Filter (FilterCondition FilterBookmark (\item -> item.isBookmark))
                ]
                [ Icon.bookmark "#F5F5F6" 16, div [ style "padding" "8px" ] [ text "Bookmarks" ] ]
            :: div
                [ style "width" "100%"
                , style "height" "2px"
                , style "border-bottom" "2px solid rgba(0, 0, 0, 0.1)"
                ]
                []
            :: (tagItems
                    |> List.map
                        (\tag ->
                            div
                                [ class <|
                                    if filter == FilterTag tag then
                                        "item selected"

                                    else
                                        "item"
                                , onClick <|
                                    Filter
                                        (FilterCondition (FilterTag tag)
                                            (\item ->
                                                List.member tag
                                                    (item.tags
                                                        |> Maybe.withDefault []
                                                        |> List.map (Maybe.withDefault "")
                                                    )
                                            )
                                        )
                                ]
                                [ Icon.tag 16, div [ style "padding" "8px" ] [ text tag ] ]
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
                ]
                [ Lazy.lazy3 sideMenu
                    model.session
                    selectedPath
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
                            , style "position" "relative"
                            ]
                            [ div
                                [ style "position" "absolute"
                                , style "left" "3px"
                                , style "top" "5px"
                                ]
                                [ Icon.search "#8C9FAE" 24 ]
                            , input
                                [ placeholder "Search"
                                , style "border-radius" "16px"
                                , style "padding" "8px"
                                , style "border" "none"
                                , style "width" "100%"
                                , style "font-size" "0.9rem"
                                , style "padding-left" "32px"
                                , onInput SearchInput
                                ]
                                []
                            ]
                        , div
                            [ class "button"
                            , style "padding" "8px"
                            , style "margin-left" "8px"
                            , onClick Export
                            ]
                            [ Icon.cloudDownload "#FEFEFE" 24, span [ class "bottom-tooltip" ] [ span [ class "text" ] [ text <| Translations.toolTipExport model.lang ] ] ]
                        , div
                            [ class "button"
                            , style "padding" "8px"
                            , onClick Import
                            ]
                            [ Icon.cloudUpload "#FEFEFE" 24, span [ class "bottom-tooltip" ] [ span [ class "text" ] [ text <| Translations.toolTipImport model.lang ] ] ]
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
                                    (\d -> Lazy.lazy2 diagramView model.timeZone d)
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
                        [ text ("Failed " ++ Utils.httpErrorToString e)
                        ]
                    ]
                ]

        _ ->
            div
                [ class "diagram-list"
                , style "align-items" "center"
                , style "justify-content" "center"
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
                        [ img [ class "keyframe anim", Asset.src Asset.logo, style "width" "64px", alt "LOADING..." ] []
                        ]
                    ]
                ]


diagramView : Zone -> DiagramItem -> Html Msg
diagramView timezone diagram =
    div
        [ class "diagram-item"
        , style "background-image" ("url(\"" ++ (diagram.thumbnail |> Maybe.withDefault "") ++ "\")")
        , style "background-size" "contain"
        , style "background-repeat" "no-repeat"
        , stopPropagationOn "click" (D.succeed ( Select diagram, True ))
        ]
        [ div
            [ class "diagram-text"
            ]
            [ div
                [ style "overflow" "hidden"
                , style "text-overflow" "ellipsis"
                , style "font-size" "1.05em"
                ]
                [ text diagram.title ]
            , div
                [ style "display" "flex"
                , style "align-items" "center"
                , style "justify-content" "space-between"
                ]
                [ div [ class "datetime" ] [ text (Utils.millisToString timezone diagram.updatedAt) ]
                , if diagram.isRemote then
                    div [ style "margin-left" "16px", class "cloud" ] [ Icon.cloudOn 14 ]

                  else
                    div [ style "margin-left" "16px", class "cloud" ] [ Icon.cloudOff 14 ]
                , div [ style "margin-left" "16px", class "remove button", stopPropagationOn "click" (D.succeed ( Remove diagram, True )) ] [ Icon.clear 18 ]
                , case ( diagram.isBookmark, diagram.isRemote ) of
                    ( True, True ) ->
                        div
                            [ class "bookmark"
                            , stopPropagationOn "click" (D.succeed ( Bookmark diagram, True ))
                            ]
                            [ Icon.bookmark "#3e9bcd" 16 ]

                    ( False, True ) ->
                        div
                            [ class "bookmark"
                            , stopPropagationOn "click" (D.succeed ( Bookmark diagram, True ))
                            ]
                            [ Icon.unbookmark "#3e9bcd" 16 ]

                    _ ->
                        Empty.view
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

        GotLocalDiagramsJson json ->
            if model.diagramList == Loading then
                ( model, Cmd.none )

            else
                let
                    localItems =
                        Result.withDefault [] <|
                            D.decodeValue (D.list DiagramItem.decoder) json
                in
                if Session.isSignedIn model.session then
                    let
                        remoteItems =
                            Request.items { url = model.apiRoot, idToken = Session.getIdToken model.session, isPublic = False } (pageOffsetAndLimit model.pageNo) False False
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
            case D.decodeValue DiagramItem.decoder diagramJson of
                Ok diagram ->
                    ( model
                    , Task.attempt Removed
                        (Request.delete { url = model.apiRoot, idToken = Session.getIdToken model.session, isPublic = False }
                            (case diagram.id of
                                Just id ->
                                    DiagramId.toString id

                                Nothing ->
                                    ""
                            )
                            |> Task.map (\_ -> Just diagram)
                        )
                    )

                Err _ ->
                    ( model, Cmd.none )

        Removed (Err _) ->
            ( model, Cmd.none )

        Removed (Ok _) ->
            ( model, getDiagrams () )

        Reload ->
            ( model, getDiagrams () )

        Bookmark diagram ->
            let
                diagramList =
                    RemoteData.withDefault [] model.diagramList |> updateIf (\item -> item.id == diagram.id) (\item -> { item | isBookmark = not item.isBookmark })
            in
            ( { model | diagramList = Success diagramList }
            , Task.attempt Bookmarked
                (Request.bookmark { url = model.apiRoot, idToken = Session.getIdToken model.session, isPublic = False }
                    (case diagram.id of
                        Just id ->
                            DiagramId.toString id

                        Nothing ->
                            ""
                    )
                    (not diagram.isBookmark)
                    |> Task.map (\_ -> Just diagram)
                )
            )

        Import ->
            ( model, Select.file [ "application/json" ] ImportFile )

        ImportFile file ->
            ( model, Task.perform ImportComplete <| File.toString file )

        ImportComplete json ->
            case DiagramItem.stringToList json of
                Ok diagrams ->
                    ( model, importDiagram <| DiagramItem.listToValue diagrams )

                Err _ ->
                    ( model, Cmd.none )

        Export ->
            case model.diagramList of
                Success diagrams ->
                    ( model, Download.string "textusm.json" "application/json" <| DiagramItem.listToString diagrams )

                _ ->
                    ( model, Cmd.none )

        _ ->
            ( model, Cmd.none )
