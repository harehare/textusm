port module Page.List exposing (DiagramList(..), Model, Msg(..), init, isNotAsked, modelOfDiagramList, notAsked, update, view)

import Api.Request as Request
import Api.RequestError exposing (RequestError)
import Constants
import Dialog.Confirm as ConfirmDialog
import File exposing (File)
import File.Download as Download
import File.Select as Select
import Html exposing (Html, div, input, span, text)
import Html.Attributes exposing (class, placeholder, style)
import Html.Events exposing (onClick, onInput, stopPropagationOn)
import Html.Lazy as Lazy
import Http
import Json.Decode as D
import Json.Encode as E
import List.Extra exposing (unique, updateIf)
import Loading exposing (LoaderType(..), defaultConfig)
import Message exposing (Lang)
import Models.Dialog as Dialog
import Monocle.Lens exposing (Lens)
import Ordering exposing (Ordering)
import RemoteData exposing (RemoteData(..), WebData)
import Return as Return exposing (Return)
import Simple.Fuzzy as Fuzzy
import Task
import Time exposing (Zone)
import Types.DiagramId as DiagramId
import Types.DiagramItem as DiagramItem exposing (DiagramItem)
import Types.DiagramLocation as DiagramLocation
import Types.Session as Session exposing (Session)
import Types.Title as Title
import Utils.Date as DateUtils
import Utils.Utils as Utils
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
    | Removed (Result RequestError String)
    | Bookmarked (Result RequestError (Maybe DiagramItem))
    | GotTimeZone Zone
    | GetDiagrams
    | GotLocalDiagramsJson D.Value
    | GotDiagrams (Result RequestError (List DiagramItem))
    | GetPublicDiagrams
    | GotPublicDiagrams (Result RequestError (List DiagramItem))
    | GetBookmarkDiagrams
    | GotBookmarkDiagrams (Result RequestError (List DiagramItem))
    | GetGistDiagrams
    | GotGistDiagrams (Result RequestError (List DiagramItem))
    | LoadNextPage PublicStatus Int
    | Export
    | Import
    | ImportFile File
    | ImportComplete String
    | ShowConfirmDialog DiagramItem
    | CloseDialog


type FilterValue
    = FilterAll
    | FilterBookmark
    | FilterPublic
    | FilterTag String
    | FilterGist


type PublicStatus
    = Public
    | Private


type FilterCondition
    = FilterCondition FilterValue (DiagramItem -> Bool)


type DiagramList
    = DiagramList (WebData (List DiagramItem)) Int Bool
    | PublicList (WebData (List DiagramItem)) Int Bool
    | GistList (WebData (List DiagramItem)) Int Bool


type alias Model =
    { searchQuery : Maybe String
    , timeZone : Zone
    , diagramList : DiagramList
    , filterCondition : FilterCondition
    , session : Session
    , apiRoot : String
    , lang : Lang
    , tags : List String
    , confirmDialog : Dialog.ConfirmDialog Msg
    }


diagramOrder : Ordering DiagramItem
diagramOrder =
    Ordering.byField (\i -> i.updatedAt |> Time.posixToMillis)
        |> Ordering.breakTiesWith (Ordering.byField (\i -> i.title |> Title.toString))
        |> Ordering.breakTiesWith (Ordering.byField (\i -> i.createdAt |> Time.posixToMillis))
        |> Ordering.reverse


modelOfDiagramList : Lens Model DiagramList
modelOfDiagramList =
    Lens .diagramList (\b a -> { a | diagramList = b })


notAsked : DiagramList
notAsked =
    DiagramList NotAsked 1 False


isNotAsked : DiagramList -> Bool
isNotAsked data =
    case data of
        DiagramList remoteData _ _ ->
            RemoteData.isNotAsked remoteData || List.isEmpty (RemoteData.withDefault [] remoteData)

        PublicList remoteData _ _ ->
            RemoteData.isNotAsked remoteData || List.isEmpty (RemoteData.withDefault [] remoteData)

        GistList remoteData _ _ ->
            RemoteData.isNotAsked remoteData || List.isEmpty (RemoteData.withDefault [] remoteData)


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
      , diagramList = notAsked
      , filterCondition = FilterCondition FilterAll (\_ -> True)
      , session = session
      , apiRoot = apiRoot
      , lang = lang
      , tags = []
      , confirmDialog = Dialog.Hide
      }
    , Cmd.batch
        [ Task.perform GotTimeZone Time.here
        , getDiagrams ()
        ]
    )


showDialog : Dialog.ConfirmDialog Msg -> Html Msg
showDialog d =
    case d of
        Dialog.Hide ->
            Empty.view

        Dialog.Show { title, message, ok, cancel } ->
            ConfirmDialog.view
                { title = title
                , message = message
                , okButton = { text = "Ok", onClick = ok }
                , cancelButton = { text = "Cancel", onClick = cancel }
                }


closeDialog : Model -> Return Msg Model
closeDialog model =
    Return.singleton { model | confirmDialog = Dialog.Hide }


tags : List DiagramItem -> List String
tags items =
    List.map
        (\item ->
            item.tags
                |> Maybe.withDefault []
                |> List.filterMap
                    (\v ->
                        Maybe.andThen
                            (\v_ ->
                                if not <| String.isEmpty v_ then
                                    Just v_

                                else
                                    Nothing
                            )
                            v
                    )
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
            , onClick GetDiagrams
            ]
            [ text "All" ]
            :: (if Session.isSignedIn session then
                    div
                        [ class <|
                            if filter == FilterPublic then
                                "item selected"

                            else
                                "item"
                        , onClick GetPublicDiagrams
                        ]
                        [ Icon.globe "#F5F5F6" 16, div [ class "p-sm" ] [ text "Public" ] ]

                else
                    div [] []
               )
            :: div
                [ class <|
                    if filter == FilterBookmark then
                        "item selected"

                    else
                        "item"
                , onClick GetBookmarkDiagrams
                ]
                [ Icon.bookmark "#F5F5F6" 14, div [ class "p-sm" ] [ text "Bookmarks" ] ]
            :: (if Session.isGithubUser session then
                    div
                        [ class <|
                            if filter == FilterGist then
                                "item selected"

                            else
                                "item"
                        , onClick GetGistDiagrams
                        ]
                        [ Icon.github "#F5F5F6" 14
                        , div [ class "p-sm" ] [ text "Gist" ]
                        ]

                else
                    div [] []
               )
            :: div
                [ class "w-full"
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
                                [ Icon.tag Constants.iconColor 13, div [ class "p-sm" ] [ text tag ] ]
                        )
               )
        )


view : Model -> Html Msg
view model =
    case ( model.diagramList, model.filterCondition ) of
        ( PublicList (Success diagrams) pageNo hasMorePage, FilterCondition FilterPublic _ ) ->
            div
                [ class "diagram-list"
                ]
                [ Lazy.lazy3 sideMenu
                    model.session
                    FilterPublic
                    model.tags
                , diagramListView
                    { timeZone = model.timeZone
                    , pageNo = pageNo
                    , hasMorePage = hasMorePage
                    , query = model.searchQuery
                    , lang = model.lang
                    , diagrams = diagrams
                    , publicStatus = Public
                    , confirmDialog = model.confirmDialog
                    }
                ]

        ( GistList (Success diagrams) pageNo hasMorePage, FilterCondition FilterGist _ ) ->
            div
                [ class "diagram-list"
                ]
                [ Lazy.lazy3 sideMenu
                    model.session
                    FilterPublic
                    model.tags
                , diagramListView
                    { timeZone = model.timeZone
                    , pageNo = pageNo
                    , hasMorePage = hasMorePage
                    , query = model.searchQuery
                    , lang = model.lang
                    , diagrams = diagrams
                    , publicStatus = Public
                    , confirmDialog = model.confirmDialog
                    }
                ]

        ( DiagramList (Success diagrams) pageNo hasMorePage, filterCondition ) ->
            let
                (FilterCondition filterValue condition) =
                    filterCondition

                displayDiagrams =
                    List.filter condition diagrams
            in
            div
                [ class "diagram-list"
                ]
                [ Lazy.lazy3 sideMenu
                    model.session
                    filterValue
                    (tags diagrams)
                , diagramListView
                    { timeZone = model.timeZone
                    , pageNo = pageNo
                    , hasMorePage = hasMorePage
                    , query = model.searchQuery
                    , lang = model.lang
                    , diagrams = displayDiagrams
                    , publicStatus = Private
                    , confirmDialog = model.confirmDialog
                    }
                ]

        ( DiagramList (Failure e) _ _, _ ) ->
            errorView e

        ( PublicList (Failure e) _ _, _ ) ->
            errorView e

        _ ->
            div
                [ class "diagram-list flex-center w-screen"
                ]
                [ div
                    [ class "flex-center w-full text-2xl"
                    , style "padding-bottom" "32px"
                    , style "color" "#8C9FAE"
                    ]
                    [ div [ style "margin-bottom" "8px" ]
                        [ Loading.render
                            Circle
                            { defaultConfig | color = "#3e9bcd", size = 40 }
                            Loading.On
                        ]
                    ]
                ]


diagramListView :
    { publicStatus : PublicStatus
    , timeZone : Zone
    , pageNo : Int
    , hasMorePage : Bool
    , query : Maybe String
    , lang : Lang
    , diagrams : List DiagramItem
    , confirmDialog : Dialog.ConfirmDialog Msg
    }
    -> Html Msg
diagramListView props =
    div
        [ style "width" "100%" ]
        [ div
            [ class "flex items-center justify-end p-md"
            , style "color" "#FEFEFE"
            ]
            [ div [ class "flex items-center w-full relative" ]
                [ div
                    [ class "absolute"
                    , style "left" "3px"
                    , style "top" "5px"
                    ]
                    [ Icon.search "#8C9FAE" 24 ]
                , input
                    [ placeholder "Search"
                    , class "w-full text-sm border-none p-sm"
                    , style "border-radius" "16px"
                    , style "padding-left" "32px"
                    , style "color" "#000"
                    , onInput SearchInput
                    ]
                    []
                ]
            , div
                [ class "button"
                , style "margin-left" "8px"
                , onClick Export
                ]
                [ Icon.cloudDownload "#FEFEFE" 24, span [ class "bottom-tooltip" ] [ span [ class "text" ] [ text <| Message.toolTipExport props.lang ] ] ]
            , div
                [ class "button"
                , onClick Import
                ]
                [ Icon.cloudUpload "#FEFEFE" 24, span [ class "bottom-tooltip" ] [ span [ class "text" ] [ text <| Message.toolTipImport props.lang ] ] ]
            ]
        , if List.isEmpty props.diagrams then
            div
                [ class "flex-center h-full text-2xl"
                , style "color" "#8C9FAE"
                , style "padding-bottom" "32px"
                ]
                [ div [ style "margin-bottom" "8px" ] [ text "NOTHING" ]
                ]

          else
            div [ class "overflow-y-auto", style "height" "calc(100vh - 120px - 2rem)" ]
                [ div
                    [ class "grid list p-sm mb-sm"
                    , style "will-change" "transform"
                    , style "border-top" "1px solid #323B46"
                    ]
                    (props.diagrams
                        |> (case props.query of
                                Just query ->
                                    List.filter (\d -> Fuzzy.match query (Title.toString d.title))

                                Nothing ->
                                    identity
                           )
                        |> List.map
                            (\d -> Lazy.lazy2 diagramView props.timeZone d)
                    )
                , if props.hasMorePage then
                    div [ class "w-full flex-center" ]
                        [ div
                            [ class "button bg-activity text-center m-sm"
                            , onClick <| LoadNextPage props.publicStatus <| props.pageNo + 1
                            ]
                            [ text "Load more" ]
                        ]

                  else
                    Empty.view
                ]
        , Lazy.lazy showDialog props.confirmDialog
        ]


diagramView : Zone -> DiagramItem -> Html Msg
diagramView timezone diagram =
    div
        [ class "diagram-item"
        , class "bg-cover"
        , class "bg-no-repeat"
        , class "relative"
        , style "background-image" ("url(\"" ++ (diagram.thumbnail |> Maybe.withDefault "") ++ "\")")
        , stopPropagationOn "click" (D.succeed ( Select diagram, True ))
        ]
        [ div
            [ class "diagram-text"
            ]
            [ div
                [ class "overflow-hidden"
                , class "overflow-ellipsis"
                , class "text-base"
                , class "font-semibold"
                ]
                [ text (Title.toString diagram.title) ]
            , div
                [ class "flex"
                , class "items-center"
                , class "justify-between"
                ]
                [ div [ class "date-time" ] [ text (DateUtils.millisToString timezone diagram.updatedAt) ]
                , div
                    [ class "absolute"
                    , class "justify-end"
                    , class "flex-wrap"
                    , class "w-full"
                    , class "hidden"
                    , class "lg:flex"
                    , style "bottom" "60px"
                    , style "transform" "scale(0.9)"
                    ]
                    (List.map viewTag (diagram.tags |> Maybe.withDefault [] |> List.map (Maybe.withDefault "")))
                ]
            ]
        , case diagram.location of
            Just DiagramLocation.Gist ->
                div [ class "cloud" ] [ Icon.github "rgba(51, 51, 51, 0.7)" 14 ]

            Just DiagramLocation.Remote ->
                div [ class "cloud" ] [ Icon.cloudOn 14 ]

            _ ->
                div [ class "cloud" ] [ Icon.cloudOff 14 ]
        , if diagram.isPublic then
            div [ class "public" ] [ Icon.lockOpen "rgba(51, 51, 51, 0.7)" 14 ]

          else
            div [ class "public" ] [ Icon.lock "rgba(51, 51, 51, 0.7)" 14 ]
        , if diagram.isPublic then
            Empty.view

          else
            div [ class "remove button", stopPropagationOn "click" (D.succeed ( ShowConfirmDialog diagram, True )) ] [ Icon.clear "#333" 18 ]
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
        ]


errorView : Http.Error -> Html Msg
errorView e =
    div
        [ class "diagram-list"
        , class "w-screen"
        ]
        [ div
            [ class "flex-center"
            , class "h-full"
            , class "text-2xl"
            , style "padding-bottom" "32px"
            , style "color" "#8C9FAE"
            ]
            [ div [ class "mb-sm" ]
                [ text ("Failed " ++ Utils.httpErrorToString e)
                ]
            ]
        ]


viewTag : String -> Html Msg
viewTag tag =
    div
        [ class "flex"
        , class "items-center"
        , class "text-center"
        , class "text-sm"
        , class "text-color"
        , class "bg-activity"
        , class "p-sm"
        , class "rounded"
        , class "m-xs"
        ]
        [ text tag ]


reload : Return.ReturnF Msg Model
reload =
    Return.andThen <| \m -> Return.return { m | diagramList = notAsked } (getDiagrams ())


update : Msg -> Return.ReturnF Msg Model
update message =
    case message of
        NoOp ->
            Return.zero

        GotTimeZone zone ->
            Return.andThen <| \m -> Return.singleton { m | timeZone = zone }

        Filter cond ->
            case cond of
                FilterCondition (FilterTag _) _ ->
                    Return.andThen <| \m -> Return.singleton { m | filterCondition = cond }

                _ ->
                    Return.zero

        SearchInput input ->
            Return.andThen <|
                \m ->
                    Return.singleton
                        { m
                            | searchQuery =
                                if String.isEmpty input then
                                    Nothing

                                else
                                    Just input
                        }

        LoadNextPage Private pageNo ->
            Return.andThen
                (\m ->
                    let
                        ( remoteData, hasMorePage ) =
                            case m.diagramList of
                                DiagramList r _ h ->
                                    ( r, h )

                                GistList _ _ _ ->
                                    ( NotAsked, False )

                                PublicList _ _ _ ->
                                    ( NotAsked, False )
                    in
                    Return.return { m | diagramList = DiagramList remoteData pageNo hasMorePage } (getDiagrams ())
                )

        LoadNextPage Public pageNo ->
            Return.andThen <| \m -> Return.return { m | diagramList = PublicList Loading pageNo True } <| Task.perform identity (Task.succeed GetPublicDiagrams)

        GetPublicDiagrams ->
            Return.andThen
                (\m ->
                    let
                        ( pageNo, hasMorePage ) =
                            case m.diagramList of
                                DiagramList _ _ _ ->
                                    ( 1, False )

                                GistList _ _ _ ->
                                    ( 1, False )

                                PublicList _ p h ->
                                    ( p, h )

                        remoteTask =
                            Request.items (Session.getIdToken m.session) (pageOffsetAndLimit pageNo) { isPublic = True, isBookmark = False }
                                |> Task.map (\i -> List.filterMap identity i)
                    in
                    Return.return { m | filterCondition = FilterCondition FilterPublic (\_ -> True), diagramList = PublicList Loading pageNo hasMorePage } <| Task.attempt GotPublicDiagrams remoteTask
                )

        GotPublicDiagrams (Ok diagrams) ->
            Return.andThen
                (\m ->
                    let
                        hasMorePage =
                            List.length diagrams >= pageSize

                        ( pageNo, allDiagrams ) =
                            case m.diagramList of
                                PublicList (Success currentDiagrams) p _ ->
                                    ( p, Success <| List.concat [ currentDiagrams, diagrams ] )

                                PublicList _ p _ ->
                                    ( p, Success diagrams )

                                _ ->
                                    ( 1, Success diagrams )
                    in
                    Return.singleton { m | diagramList = PublicList allDiagrams pageNo hasMorePage }
                )

        GotPublicDiagrams (Err _) ->
            Return.zero

        GetBookmarkDiagrams ->
            Return.andThen
                (\m ->
                    let
                        ( pageNo, hasMorePage ) =
                            case m.diagramList of
                                DiagramList _ p h ->
                                    ( p, h )

                                GistList _ _ _ ->
                                    ( 1, False )

                                PublicList _ _ _ ->
                                    ( 1, False )

                        remoteTask =
                            Request.items (Session.getIdToken m.session) (pageOffsetAndLimit pageNo) { isPublic = False, isBookmark = True }
                                |> Task.map (\i -> List.filterMap identity i)
                    in
                    Return.return { m | filterCondition = FilterCondition FilterBookmark (\_ -> True), diagramList = DiagramList Loading pageNo hasMorePage } <| Task.attempt GotBookmarkDiagrams remoteTask
                )

        GetDiagrams ->
            reload

        GotBookmarkDiagrams (Ok diagrams) ->
            Return.andThen
                (\m ->
                    let
                        hasMorePage =
                            List.length diagrams >= pageSize

                        ( pageNo, allDiagrams ) =
                            case m.diagramList of
                                DiagramList (Success currentDiagrams) p _ ->
                                    ( p, Success <| List.concat [ currentDiagrams, diagrams ] )

                                DiagramList _ p _ ->
                                    ( p, Success diagrams )

                                _ ->
                                    ( 1, Success diagrams )
                    in
                    Return.singleton { m | diagramList = DiagramList allDiagrams pageNo hasMorePage }
                )

        GotBookmarkDiagrams (Err _) ->
            Return.zero

        GetGistDiagrams ->
            Return.andThen
                (\m ->
                    let
                        ( pageNo, hasMorePage ) =
                            case m.diagramList of
                                DiagramList _ p h ->
                                    ( p, h )

                                GistList _ p h ->
                                    ( p, h )

                                PublicList _ p h ->
                                    ( p, h )

                        remoteTask =
                            Request.gistItems (Session.getIdToken m.session) (pageOffsetAndLimit pageNo)
                                |> Task.map (\i -> List.filterMap identity i)
                    in
                    Return.return { m | filterCondition = FilterCondition FilterGist (\_ -> True), diagramList = GistList Loading pageNo hasMorePage } <| Task.attempt GotGistDiagrams remoteTask
                )

        GotGistDiagrams (Ok diagrams) ->
            Return.andThen
                (\m ->
                    let
                        hasMorePage =
                            List.length diagrams >= pageSize

                        ( pageNo, allDiagrams ) =
                            case m.diagramList of
                                GistList (Success currentDiagrams) p _ ->
                                    ( p, Success <| List.concat [ currentDiagrams, diagrams ] )

                                GistList _ p _ ->
                                    ( p, Success diagrams )

                                _ ->
                                    ( 1, Success diagrams )
                    in
                    Return.singleton { m | diagramList = GistList allDiagrams pageNo hasMorePage }
                )

        GotGistDiagrams (Err _) ->
            Return.zero

        GotLocalDiagramsJson json ->
            Return.andThen
                (\m ->
                    case m.diagramList of
                        DiagramList Loading _ _ ->
                            Return.singleton m

                        DiagramList _ pageNo _ ->
                            let
                                localItems =
                                    Result.withDefault [] <|
                                        D.decodeValue (D.list DiagramItem.decoder) json
                            in
                            if Session.isSignedIn m.session then
                                let
                                    remoteItems =
                                        Request.allItems (Session.getIdToken m.session) (pageOffsetAndLimit pageNo)
                                            |> Task.map (\i -> i |> Maybe.withDefault [])

                                    items =
                                        remoteItems
                                            |> Task.map
                                                (\item ->
                                                    List.concat [ localItems, item ]
                                                        |> List.sortWith diagramOrder
                                                )
                                in
                                Return.return
                                    { m
                                        | diagramList =
                                            case m.diagramList of
                                                DiagramList NotAsked _ _ ->
                                                    DiagramList Loading 1 False

                                                _ ->
                                                    m.diagramList
                                    }
                                <|
                                    Task.attempt GotDiagrams items

                            else
                                Return.singleton { m | diagramList = DiagramList (Success localItems) 1 False }

                        _ ->
                            Return.singleton m
                )

        GotDiagrams (Err _) ->
            Return.zero

        GotDiagrams (Ok items) ->
            Return.andThen
                (\m ->
                    let
                        hasMorePage =
                            List.length items >= pageSize

                        ( remoteData, pageNo ) =
                            case m.diagramList of
                                DiagramList r p _ ->
                                    ( r, p )

                                GistList r p _ ->
                                    ( r, p )

                                PublicList r p _ ->
                                    ( r, p )
                    in
                    Return.singleton
                        { m
                            | diagramList =
                                if List.isEmpty <| RemoteData.withDefault [] remoteData then
                                    DiagramList (Success items) 1 hasMorePage

                                else
                                    DiagramList (RemoteData.andThen (\currentItems -> Success <| List.concat [ currentItems, items ]) remoteData) pageNo hasMorePage
                            , tags = List.concat [ m.tags, tags items ]
                        }
                )

        Remove diagram ->
            Return.andThen closeDialog
                >> Return.command (removeDiagrams (DiagramItem.encoder diagram))

        RemoveRemote diagramJson ->
            Return.andThen
                (\m ->
                    case D.decodeValue DiagramItem.decoder diagramJson of
                        Ok diagram ->
                            Return.return m
                                (Task.attempt Removed
                                    (Request.delete (Session.getIdToken m.session)
                                        (diagram.id |> Maybe.withDefault (DiagramId.fromString "") |> DiagramId.toString)
                                        False
                                        |> Task.map (\id -> id)
                                    )
                                )

                        Err _ ->
                            Return.singleton m
                )

        Removed (Err _) ->
            Return.zero

        Removed (Ok _) ->
            reload

        Reload ->
            reload

        Bookmark diagram ->
            Return.andThen
                (\m ->
                    let
                        ( remoteData, pageNo, hasMorePage ) =
                            case m.diagramList of
                                DiagramList r p h ->
                                    ( r, p, h )

                                GistList r p h ->
                                    ( r, p, h )

                                PublicList r p h ->
                                    ( r, p, h )

                        diagramList =
                            RemoteData.withDefault [] remoteData |> updateIf (\item -> item.id == diagram.id) (\item -> { item | isBookmark = not item.isBookmark })
                    in
                    Return.return { m | diagramList = DiagramList (Success diagramList) pageNo hasMorePage }
                        (Task.attempt Bookmarked
                            (Request.bookmark (Session.getIdToken m.session)
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
                )

        Import ->
            Return.command <| Select.file [ "application/json" ] ImportFile

        ImportFile file ->
            Return.command <| Task.perform ImportComplete <| File.toString file

        ImportComplete json ->
            case DiagramItem.stringToList json of
                Ok diagrams ->
                    Return.command <| importDiagram <| DiagramItem.listToValue diagrams

                Err _ ->
                    Return.zero

        Export ->
            Return.andThen
                (\m ->
                    case m.diagramList of
                        DiagramList (Success diagrams) _ _ ->
                            Return.return m <| Download.string "textusm.json" "application/json" <| DiagramItem.listToString diagrams

                        _ ->
                            Return.singleton m
                )

        CloseDialog ->
            Return.andThen closeDialog

        ShowConfirmDialog d ->
            Return.andThen <|
                \m ->
                    Return.singleton
                        { m
                            | confirmDialog =
                                Dialog.Show
                                    { title = "Confirmation"
                                    , message = "Are you sure you want to delete " ++ Title.toString d.title ++ " diagram?`"
                                    , ok = Remove d
                                    , cancel = CloseDialog
                                    }
                        }

        _ ->
            Return.zero
