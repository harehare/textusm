module Main exposing (init, main, view)

import Api.Diagram as DiagramApi
import Api.Export
import Api.UrlShorter as UrlShorterApi
import Basics exposing (max)
import Browser
import Browser.Dom as Dom
import Browser.Events exposing (Visibility(..))
import Browser.Navigation as Nav
import Components.Diagram as Diagram
import File exposing (name)
import File.Download as Download
import File.Select as Select
import Html exposing (Html, div, main_)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick)
import Html.Lazy exposing (lazy, lazy2, lazy4, lazy5, lazy7, lazy8)
import Json.Decode as D
import Maybe.Extra exposing (isJust)
import Models.Diagram as DiagramModel
import Models.DiagramItem exposing (DiagramItem)
import Models.DiagramType as DiagramType
import Models.Model exposing (Model, Msg(..), Notification(..), Settings, ShareUrl(..), Window)
import Models.User as User
import Parser
import Route exposing (Route(..), toRoute)
import Settings exposing (settingsDecoder)
import String
import Subscriptions exposing (..)
import Task
import Time exposing (Zone)
import Url as Url exposing (percentDecode)
import Utils
import Views.DiagramList as DiagramList
import Views.Editor as Editor
import Views.Header as Header
import Views.Icon as Icon
import Views.Logo as Logo
import Views.Menu as Menu
import Views.Notification as Notification
import Views.ProgressBar as ProgressBar
import Views.SplitWindow as SplitWindow
import Views.Tab as Tab


init : ( String, Settings ) -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    let
        ( apiRoot, settings ) =
            flags

        ( model, cmds ) =
            changeRouteTo (toRoute url)
                { id = Nothing
                , diagramModel = Diagram.init settings.storyMap
                , text = settings.text |> Maybe.withDefault ""
                , openMenu = Nothing
                , title = settings.title
                , isEditTitle = False
                , window =
                    { position = settings.position |> Maybe.withDefault 0
                    , moveStart = False
                    , moveX = 0
                    , fullscreen = False
                    }
                , share = Nothing
                , settings = settings
                , notification = Nothing
                , url = url
                , key = key
                , tabIndex = 1
                , progress = True
                , apiRoot = apiRoot
                , diagrams = Nothing
                , timezone = Nothing
                , loginUser = Nothing
                , isOnline = True
                }
    in
    ( model
    , Cmd.batch
        [ Task.perform GotTimeZone Time.here
        , cmds
        ]
    )


view : Model -> Html Msg
view model =
    main_
        [ style "position" "relative"
        , style "width" "100vw"
        , style "height" "100vh"
        , onClick CloseMenu
        ]
        [ lazy7 Header.view model.diagramModel.width model.loginUser (toRoute model.url) model.title model.isEditTitle model.window.fullscreen model.openMenu
        , lazy networkStatus model.isOnline
        , lazy showNotification model.notification
        , lazy showProgressbar model.progress
        , div
            [ class "main" ]
            [ lazy5 Menu.view (toRoute model.url) model.diagramModel.width model.window.fullscreen model.openMenu model.isOnline
            , lazy8 mainView model.settings model.diagramModel model.diagrams model.timezone model.window model.tabIndex model.text model.url
            ]
        ]


mainView : Settings -> DiagramModel.Model -> Maybe (List DiagramItem) -> Maybe Zone -> Window -> Int -> String -> Url.Url -> Html Msg
mainView settings diagramModel diagrams zone window tabIndex text url =
    let
        mainWindow =
            if diagramModel.width > 0 && Utils.isPhone diagramModel.width then
                lazy4 Tab.view
                    diagramModel.settings.backgroundColor
                    tabIndex

            else
                lazy4 SplitWindow.view
                    diagramModel.settings.backgroundColor
                    window
    in
    case toRoute url of
        Route.List ->
            lazy2 DiagramList.view (zone |> Maybe.withDefault Time.utc) diagrams

        _ ->
            mainWindow
                (lazy2 Editor.view settings (toRoute url))
                (if String.isEmpty text then
                    Logo.view

                 else
                    lazy Diagram.view diagramModel
                        |> Html.map UpdateDiagram
                )


main : Program ( String, Settings ) Model Msg
main =
    Browser.application
        { init = init
        , update = update
        , view =
            \m ->
                { title = Maybe.withDefault "untitled" m.title ++ " | TextUSM"
                , body = [ view m ]
                }
        , subscriptions = subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }


showProgressbar : Bool -> Html Msg
showProgressbar show =
    if show then
        ProgressBar.view

    else
        div [] []


showNotification : Maybe Notification -> Html Msg
showNotification notify =
    case notify of
        Just notification ->
            Notification.view notification

        Nothing ->
            div [] []


networkStatus : Bool -> Html Msg
networkStatus isOnline =
    if isOnline then
        div [] []

    else
        div
            [ style "position" "fixed"
            , style "top" "40px"
            , style "right" "10px"
            , style "z-index" "10"
            ]
            [ Icon.cloudOff 24 ]



-- Update


changeRouteTo : Route -> Model -> ( Model, Cmd Msg )
changeRouteTo route model =
    let
        updatedModel =
            { model | diagrams = Nothing }

        getCmds : List (Cmd Msg) -> Cmd Msg
        getCmds cmds =
            Cmd.batch (Task.perform Init Dom.getViewport :: cmds)
    in
    case route of
        Route.List ->
            ( updatedModel, getCmds [ getDiagrams () ] )

        Route.Settings ->
            ( updatedModel, getCmds [] )

        Route.Help ->
            ( updatedModel, getCmds [] )

        Route.CallbackTrello (Just token) (Just code) ->
            let
                usm =
                    Diagram.update (DiagramModel.OnChangeText model.text) model.diagramModel

                req =
                    Api.Export.createRequest token
                        (Just code)
                        Nothing
                        usm.hierarchy
                        (Parser.parseComment model.text)
                        (if model.title == Just "" then
                            "UnTitled"

                         else
                            model.title |> Maybe.withDefault "UnTitled"
                        )
                        usm.items
            in
            ( { updatedModel
                | progress = True
              }
            , getCmds
                [ Task.perform identity (Task.succeed (OnNotification (Info "Start export to Trello." Nothing)))
                , Task.attempt Exported (Api.Export.export model.apiRoot Api.Export.Trello req)
                ]
            )

        Route.Embed diagram title path ->
            let
                diagramModel =
                    model.diagramModel

                newDiagramModel =
                    { diagramModel
                        | diagramType =
                            DiagramType.fromString diagram
                    }
            in
            ( { updatedModel
                | window =
                    { position = model.window.position
                    , moveStart = model.window.moveStart
                    , moveX = model.window.moveX
                    , fullscreen = True
                    }
                , diagramModel = newDiagramModel
                , title =
                    if title == "untitled" then
                        Nothing

                    else
                        Just title
              }
            , getCmds [ decodeShareText path ]
            )

        Route.Share diagram title path ->
            let
                diagramModel =
                    model.diagramModel

                newDiagramModel =
                    { diagramModel
                        | diagramType =
                            DiagramType.fromString diagram
                    }
            in
            ( { updatedModel
                | diagramModel = newDiagramModel
                , title =
                    if title == "untitled" then
                        Nothing

                    else
                        percentDecode title
              }
            , getCmds [ decodeShareText path ]
            )

        Route.UsmView settingsJson ->
            changeRouteTo (Route.View "usm" settingsJson) updatedModel

        Route.View diagram settingsJson ->
            let
                maybeSettings =
                    percentDecode settingsJson
                        |> Maybe.andThen
                            (\x ->
                                D.decodeString settingsDecoder x |> Result.toMaybe
                            )

                diagramModel =
                    model.diagramModel

                newDiagramModel =
                    { diagramModel
                        | diagramType =
                            DiagramType.fromString diagram
                    }

                updatedDiagramModel =
                    case maybeSettings of
                        Just settings ->
                            { newDiagramModel | settings = settings.storyMap, showZoomControl = False, fullscreen = True }

                        Nothing ->
                            { newDiagramModel | showZoomControl = False, fullscreen = True }
            in
            case maybeSettings of
                Just settings ->
                    ( { updatedModel
                        | settings = settings
                        , diagramModel = updatedDiagramModel
                        , window =
                            { position = model.window.position
                            , moveStart = model.window.moveStart
                            , moveX = model.window.moveX
                            , fullscreen = True
                            }
                        , text = String.replace "\\n" "\n" (settings.text |> Maybe.withDefault "")
                        , title = settings.title
                      }
                    , getCmds []
                    )

                Nothing ->
                    ( updatedModel, getCmds [] )

        Route.BusinessModelCanvas ->
            let
                diagramModel =
                    model.diagramModel

                newDiagramModel =
                    { diagramModel | diagramType = DiagramType.BusinessModelCanvas }
            in
            ( { updatedModel | diagramModel = newDiagramModel, id = Nothing }
            , getCmds []
            )

        Route.OpportunityCanvas ->
            let
                diagramModel =
                    model.diagramModel

                newDiagramModel =
                    { diagramModel | diagramType = DiagramType.OpportunityCanvas }
            in
            ( { updatedModel | diagramModel = newDiagramModel, id = Nothing }
            , getCmds []
            )

        Route.FourLs ->
            let
                diagramModel =
                    model.diagramModel

                newDiagramModel =
                    { diagramModel | diagramType = DiagramType.FourLs }
            in
            ( { updatedModel | diagramModel = newDiagramModel, id = Nothing }
            , getCmds []
            )

        Route.StartStopContinue ->
            let
                diagramModel =
                    model.diagramModel

                newDiagramModel =
                    { diagramModel | diagramType = DiagramType.StartStopContinue }
            in
            ( { updatedModel | diagramModel = newDiagramModel, id = Nothing }
            , getCmds []
            )

        Route.Kpt ->
            let
                diagramModel =
                    model.diagramModel

                newDiagramModel =
                    { diagramModel | diagramType = DiagramType.Kpt }
            in
            ( { updatedModel | diagramModel = newDiagramModel, id = Nothing }
            , getCmds []
            )

        _ ->
            let
                diagramModel =
                    model.diagramModel

                newDiagramModel =
                    { diagramModel | diagramType = DiagramType.UserStoryMap }
            in
            ( { updatedModel | diagramModel = newDiagramModel, id = Nothing }
            , getCmds []
            )


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        NoOp ->
            ( model, Cmd.none )

        UpdateDiagram subMsg ->
            case subMsg of
                DiagramModel.ItemClick item ->
                    ( model, selectLine (item.lineNo + 1) )

                DiagramModel.OnResize _ _ ->
                    ( { model | diagramModel = Diagram.update subMsg model.diagramModel }, loadEditor model.text )

                DiagramModel.PinchIn _ ->
                    ( { model | diagramModel = Diagram.update subMsg model.diagramModel }, Task.perform identity (Task.succeed (UpdateDiagram DiagramModel.ZoomIn)) )

                DiagramModel.PinchOut _ ->
                    ( { model | diagramModel = Diagram.update subMsg model.diagramModel }, Task.perform identity (Task.succeed (UpdateDiagram DiagramModel.ZoomOut)) )

                DiagramModel.OnChangeText text ->
                    let
                        diagramModel =
                            Diagram.update subMsg model.diagramModel
                    in
                    case diagramModel.error of
                        Just err ->
                            ( { model | text = text, diagramModel = diagramModel }, errorLine err )

                        Nothing ->
                            ( { model | text = text, diagramModel = diagramModel }, errorLine "" )

                _ ->
                    ( { model | diagramModel = Diagram.update subMsg model.diagramModel }, Cmd.none )

        Init window ->
            let
                usm =
                    Diagram.update (DiagramModel.Init model.diagramModel.settings window model.text) model.diagramModel
            in
            case usm.error of
                Just err ->
                    ( { model
                        | diagramModel = usm
                        , progress = False
                      }
                    , Cmd.batch
                        [ errorLine err
                        , loadEditor model.text
                        ]
                    )

                Nothing ->
                    ( { model
                        | diagramModel = usm
                        , progress = False
                      }
                    , loadEditor model.text
                    )

        GotTimeZone zone ->
            ( { model | timezone = Just zone }, Cmd.none )

        DownloadPng ->
            let
                width =
                    Basics.max model.diagramModel.svg.width model.diagramModel.width

                height =
                    case model.diagramModel.diagramType of
                        DiagramType.UserStoryMap ->
                            Basics.max model.diagramModel.svg.height model.diagramModel.height

                        _ ->
                            1000
            in
            ( model
            , downloadPng
                { width = width
                , height = height
                , id = "usm"
                , title = Utils.getTitle model.title ++ ".png"
                }
            )

        DownloadSvg ->
            let
                width =
                    Basics.max model.diagramModel.svg.width model.diagramModel.width

                height =
                    case model.diagramModel.diagramType of
                        DiagramType.UserStoryMap ->
                            Basics.max model.diagramModel.svg.height model.diagramModel.height

                        _ ->
                            1000
            in
            ( model
            , downloadSvg
                { width = width
                , height = height
                , id = "usm"
                , title = Utils.getTitle model.title ++ ".svg"
                }
            )

        StartDownloadSvg image ->
            ( model, Cmd.batch [ Download.string (Utils.getTitle model.title ++ ".svg") "image/svg+xml" image, Task.perform identity (Task.succeed CloseMenu) ] )

        OpenMenu menu ->
            ( { model | openMenu = Just menu }, Cmd.none )

        CloseMenu ->
            ( { model | openMenu = Nothing }, Cmd.none )

        FileSelect ->
            ( model, Select.file [ "text/plain", "text/markdown" ] FileSelected )

        FileSelected file ->
            ( { model | title = Just (File.name file) }, Utils.fileLoad file FileLoaded )

        FileLoaded text ->
            ( model, Cmd.batch [ Task.perform identity (Task.succeed (UpdateDiagram (DiagramModel.OnChangeText text))), loadText text ] )

        SaveToFileSystem ->
            let
                title =
                    model.title |> Maybe.withDefault ""
            in
            ( model, Download.string title "text/plain" model.text )

        Save ->
            let
                title =
                    model.title |> Maybe.withDefault ""

                isRemote =
                    isJust model.loginUser
            in
            ( { model
                | notification =
                    if not isRemote then
                        Just (Info ("Successfully \"" ++ title ++ "\" saved.") Nothing)

                    else
                        Nothing
              }
            , Cmd.batch
                [ saveDiagram
                    ( { id = model.id
                      , title = title
                      , text = model.text
                      , thumbnail = Nothing
                      , diagramPath = DiagramType.toString model.diagramModel.diagramType
                      , isRemote = isRemote
                      , updatedAt = Nothing
                      , isPublic = False
                      }
                    , Nothing
                    )
                , if not isRemote then
                    Utils.delay 3000 OnCloseNotification

                  else
                    Cmd.none
                ]
            )

        SaveToRemote diagram ->
            let
                save =
                    DiagramApi.save (Utils.getIdToken model.loginUser) model.apiRoot diagram
            in
            ( { model | progress = True }, Task.attempt Saved save )

        Saved (Err _) ->
            ( { model
                | progress = False
              }
            , Cmd.batch
                [ Utils.delay 3000
                    OnCloseNotification
                , Utils.showWarningMessage ("Successfully \"" ++ (model.title |> Maybe.withDefault "") ++ "\" saved.") Nothing
                , saveDiagram
                    ( { id = model.id
                      , title = model.title |> Maybe.withDefault ""
                      , text = model.text
                      , thumbnail = Nothing
                      , diagramPath = DiagramType.toString model.diagramModel.diagramType
                      , isRemote = False
                      , updatedAt = Nothing
                      , isPublic = False
                      }
                    , Nothing
                    )
                ]
            )

        Saved (Ok _) ->
            ( { model | progress = False }
            , Cmd.batch
                [ Utils.delay 3000 OnCloseNotification
                , Utils.showInfoMessage ("Successfully \"" ++ (model.title |> Maybe.withDefault "") ++ "\" saved.") Nothing
                ]
            )

        Shortcuts x ->
            if x == "save" then
                update Save model

            else if x == "open" then
                update GetDiagrams model

            else
                ( model, Cmd.none )

        StartEditTitle ->
            ( { model | isEditTitle = True }
            , Task.attempt
                (\_ -> NoOp)
              <|
                Dom.focus "title"
            )

        EndEditTitle code isComposing ->
            if code == 13 && not isComposing then
                ( { model | isEditTitle = False }, Cmd.none )

            else
                ( model, Cmd.none )

        EditTitle title ->
            ( { model
                | title =
                    if String.isEmpty title then
                        Nothing

                    else
                        Just title
              }
            , Cmd.none
            )

        EditSettings ->
            ( model
            , Nav.pushUrl model.key (Route.toString Route.Settings)
            )

        ShowHelp ->
            ( model
            , Nav.pushUrl model.key (Route.toString Route.Help)
            )

        ApplySettings settings ->
            let
                diagramModel =
                    model.diagramModel

                newDiagramModel =
                    { diagramModel | settings = settings.storyMap }
            in
            ( { model | settings = settings, diagramModel = newDiagramModel }, Cmd.none )

        OnVisibilityChange visible ->
            if model.window.fullscreen then
                ( model, Cmd.none )

            else if visible == Hidden then
                let
                    newSettings =
                        { position = Just model.window.position
                        , font = model.settings.font
                        , diagramId = model.id
                        , storyMap = model.settings.storyMap
                        , text = Just model.text
                        , title =
                            model.title
                        , github = model.settings.github
                        }
                in
                ( { model | settings = newSettings }
                , saveSettings newSettings
                )

            else
                ( model, Cmd.none )

        OnStartWindowResize x ->
            ( { model
                | window =
                    { position = model.window.position
                    , moveStart = True
                    , moveX = x
                    , fullscreen = model.window.fullscreen
                    }
              }
            , Cmd.none
            )

        Stop ->
            ( { model
                | window =
                    { position = model.window.position
                    , moveStart = False
                    , moveX = model.window.moveX
                    , fullscreen = model.window.fullscreen
                    }
              }
            , Cmd.none
            )

        OnWindowResize x ->
            ( { model
                | window =
                    { position = model.window.position + x - model.window.moveX
                    , moveStart = True
                    , moveX = x
                    , fullscreen = model.window.fullscreen
                    }
              }
            , Cmd.none
            )

        OnCurrentShareUrl ->
            if isJust model.loginUser then
                ( { model | progress = True }
                , encodeShareText
                    { diagramType =
                        DiagramType.toString model.diagramModel.diagramType
                    , title = model.title
                    , text = model.text
                    }
                )

            else
                update Login model

        GetShortUrl (Err e) ->
            ( { model | progress = False }
            , Cmd.batch
                [ Task.perform identity (Task.succeed (OnNotification (Error ("Error. " ++ Utils.httpErrorToString e))))
                , Utils.delay 3000 OnCloseNotification
                ]
            )

        GetShortUrl (Ok res) ->
            ( { model | progress = False }
            , Cmd.batch
                [ copyClipboard res.shortLink
                , Task.perform identity
                    (Task.succeed
                        (OnNotification
                            (Info
                                ("Copy \"" ++ res.shortLink ++ "\" to clipboard.")
                                (Just res.shortLink)
                            )
                        )
                    )
                , Utils.delay 3000 OnCloseNotification
                ]
            )

        OnShareUrl shareInfo ->
            ( model
            , encodeShareText shareInfo
            )

        OnNotification notification ->
            ( { model | notification = Just notification }, Cmd.none )

        OnAutoCloseNotification notification ->
            ( { model | notification = Just notification }, Utils.delay 3000 OnCloseNotification )

        OnCloseNotification ->
            ( { model | notification = Nothing }, Cmd.none )

        OnEncodeShareText path ->
            ( { model | share = Just (ShareUrl path) }, Task.attempt GetShortUrl (UrlShorterApi.urlShorter (Utils.getIdToken model.loginUser) model.apiRoot path) )

        OnChangeNetworkStatus isOnline ->
            ( { model | isOnline = isOnline }, Cmd.none )

        OnDecodeShareText text ->
            ( model, Task.perform identity (Task.succeed (FileLoaded text)) )

        TabSelect tab ->
            ( { model | tabIndex = tab }, layoutEditor 100 )

        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        UrlChanged url ->
            let
                updatedModel =
                    { model | url = url }
            in
            changeRouteTo (toRoute url) updatedModel

        GetAccessTokenForTrello ->
            ( model, Api.Export.getAccessToken model.apiRoot Api.Export.Trello )

        GetAccessTokenForGitHub ->
            ( model, getAccessTokenForGitHub () )

        Exported (Err e) ->
            ( { model | progress = False }
            , Cmd.batch
                [ Utils.showErrorMessage ("Error export. " ++ Utils.httpErrorToString e)
                , Nav.pushUrl model.key (Route.toString Route.Home)
                ]
            )

        Exported (Ok result) ->
            let
                messageCmd =
                    if result.failed > 0 then
                        Utils.showWarningMessage "Finish export, but some errors occurred. Click to open Trello." (Just result.url)

                    else
                        Utils.showInfoMessage "Finish export. Click to open Trello." (Just result.url)
            in
            ( { model | progress = False }
            , Cmd.batch
                [ messageCmd
                , Nav.pushUrl model.key (Route.toString Route.Home)
                ]
            )

        DoOpenUrl url ->
            ( model, Nav.load url )

        ExportGitHub token ->
            let
                req =
                    Maybe.map
                        (\g ->
                            Api.Export.createRequest
                                token
                                Nothing
                                (Just
                                    { owner = g.owner
                                    , repo = g.repo
                                    }
                                )
                                model.diagramModel.hierarchy
                                (Parser.parseComment model.text)
                                (if model.title == Just "" then
                                    "untitled"

                                 else
                                    model.title |> Maybe.withDefault "untitled"
                                )
                                model.diagramModel.items
                        )
                        model.settings.github
            in
            ( { model
                | progress = isJust req
              }
            , case req of
                Just r ->
                    Cmd.batch
                        [ Utils.showInfoMessage "Start export to Github." Nothing
                        , Task.attempt Exported (Api.Export.export model.apiRoot Api.Export.Github r)
                        ]

                Nothing ->
                    Cmd.batch
                        [ Utils.showWarningMessage "Invalid settings. Please add GitHub Owner and Repository to settings." Nothing
                        , Task.perform identity (Task.succeed EditSettings)
                        ]
            )

        LoadLocalDiagrams localItems ->
            case model.loginUser of
                Just _ ->
                    let
                        remoteItems =
                            DiagramApi.items (Maybe.map (\u -> User.getIdToken u) model.loginUser) 1 model.apiRoot

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
                    ( { model | progress = True }, Task.attempt LoadDiagrams items )

                Nothing ->
                    ( { model | diagrams = Just localItems }, Cmd.none )

        LoadDiagrams (Err ( items, err )) ->
            ( { model | progress = False, diagrams = Just items }
            , Cmd.batch
                [ Utils.delay 3000 OnCloseNotification
                , Utils.showWarningMessage "Failed to laod files." Nothing
                ]
            )

        LoadDiagrams (Ok items) ->
            ( { model | progress = False, diagrams = Just items }, Cmd.none )

        GetDiagrams ->
            ( model, Nav.pushUrl model.key (Route.toString Route.List) )

        RemoveDiagram diagram ->
            ( model, removeDiagrams diagram )

        RemoveRemoteDiagram diagram ->
            ( model
            , Task.attempt Removed
                (DiagramApi.remove (Utils.getIdToken model.loginUser) model.apiRoot (diagram.id |> Maybe.withDefault "")
                    |> Task.mapError (Tuple.pair diagram)
                    |> Task.map (\_ -> diagram)
                )
            )

        Removed (Err ( diagram, _ )) ->
            ( model
            , Cmd.batch
                [ Utils.delay 3000 OnCloseNotification
                , Utils.showErrorMessage
                    ("Failed \"" ++ diagram.title ++ "\" remove")
                ]
            )

        Removed (Ok diagram) ->
            ( model
            , Cmd.batch
                [ getDiagrams ()
                , Utils.delay 3000 OnCloseNotification
                , Utils.showInfoMessage
                    ("Successfully \"" ++ diagram.title ++ "\" removed")
                    Nothing
                ]
            )

        RemovedDiagram ( diagram, removed ) ->
            ( model
            , if removed then
                Cmd.batch
                    [ getDiagrams ()
                    , Utils.delay 3000 OnCloseNotification
                    , Utils.showInfoMessage
                        ("Successfully \"" ++ diagram.title ++ "\" removed")
                        Nothing
                    ]

              else
                Cmd.none
            )

        Open diagram ->
            if diagram.isRemote then
                ( { model | progress = True }
                , Task.attempt Opened
                    (DiagramApi.item (Utils.getIdToken model.loginUser) model.apiRoot (diagram.id |> Maybe.withDefault "")
                        |> Task.mapError (Tuple.pair diagram)
                    )
                )

            else
                ( { model
                    | id = diagram.id
                    , text = diagram.text
                    , title = Just diagram.title
                  }
                , Nav.pushUrl model.key diagram.diagramPath
                )

        Opened (Err ( diagram, _ )) ->
            ( { model | progress = False }
            , Cmd.batch
                [ Utils.delay 3000 OnCloseNotification
                , Utils.showWarningMessage ("Failed to load \"" ++ diagram.title ++ "\".") Nothing
                ]
            )

        Opened (Ok diagram) ->
            ( { model
                | progress = False
                , id = diagram.id
                , text = diagram.text
                , title = Just diagram.title
              }
            , Nav.pushUrl model.key diagram.diagramPath
            )

        UpdateSettings getSetting value ->
            let
                settings =
                    getSetting value

                diagramModel =
                    model.diagramModel

                newDiagramModel =
                    { diagramModel | settings = settings.storyMap }
            in
            ( { model | settings = settings, diagramModel = newDiagramModel }, Cmd.none )

        Login ->
            ( model, login () )

        Logout ->
            ( model, logout () )

        OnAuthStateChanged user ->
            ( { model | loginUser = user }, Cmd.none )

        HistoryBack ->
            ( { model | diagrams = Nothing }, Nav.back model.key 1 )

        MoveTo url ->
            ( { model | diagrams = Nothing }, Nav.pushUrl model.key url )

        MoveToBack ->
            ( model, Nav.back model.key 1 )

        NewUserStoryMap ->
            ( { model
                | id = Nothing
                , title = Nothing
              }
            , Nav.pushUrl model.key (Route.toString Route.Home)
            )

        NewBusinessModelCanvas ->
            let
                text =
                    "👥 Key Partners\n📊 Customer Segments\n🎁 Value Proposition\n✅ Key Activities\n🚚 Channels\n💰 Revenue Streams\n🏷️ Cost Structure\n💪 Key Resources\n💙 Customer Relationships"
            in
            ( { model
                | text = text
                , id = Nothing
                , title = Nothing
              }
            , Cmd.batch
                [ saveToLocal model (Just (Route.toString Route.BusinessModelCanvas))
                , loadText text
                ]
            )

        NewOpportunityCanvas ->
            let
                text =
                    """Problems
Solution Ideas
Users and Customers
Solutions Today
Business Challenges
How will Users use Solution?
User Metrics
Adoption Strategy
Business Benefits and Metrics
Budget
"""
            in
            ( { model
                | text = text
                , id = Nothing
                , title = Nothing
              }
            , Cmd.batch
                [ saveToLocal model (Just (Route.toString Route.OpportunityCanvas))
                , loadText text
                ]
            )

        NewFourLs ->
            let
                text =
                    "Liked\nLearned\nLacked\nLonged for"
            in
            ( { model
                | text = text
                , id = Nothing
                , title = Nothing
              }
            , Cmd.batch
                [ saveToLocal model (Just (Route.toString Route.FourLs))
                , loadText text
                ]
            )

        NewStartStopContinue ->
            let
                text =
                    "Start\nStop\nContinue"
            in
            ( { model
                | text = text
                , id = Nothing
                , title = Nothing
              }
            , Cmd.batch
                [ saveToLocal model (Just (Route.toString Route.StartStopContinue))
                , loadText text
                ]
            )

        NewKpt ->
            let
                text =
                    "K\nP\nT"
            in
            ( { model
                | text = text
                , id = Nothing
                , title = Nothing
              }
            , Cmd.batch
                [ saveToLocal model (Just (Route.toString Route.Kpt))
                , loadText text
                ]
            )


saveToLocal : Model -> Maybe String -> Cmd Msg
saveToLocal model url =
    saveDiagram
        ( { id = Nothing
          , title = model.title |> Maybe.withDefault ""
          , text = model.text
          , thumbnail = Nothing
          , diagramPath = DiagramType.toString model.diagramModel.diagramType
          , isRemote = False
          , updatedAt = Nothing
          , isPublic = False
          }
        , url
        )
