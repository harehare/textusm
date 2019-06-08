module Main exposing (init, main, view)

import Api
import Basics exposing (max)
import Browser
import Browser.Dom as Dom
import Browser.Events exposing (Visibility(..))
import Browser.Navigation as Nav
import Components.Diagram as Diagram
import Constants
import File exposing (name)
import File.Download as Download
import File.Select as Select
import Html exposing (Html, div, main_)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick)
import Html.Lazy exposing (lazy, lazy3, lazy4)
import Json.Decode as D
import Maybe.Extra exposing (isJust)
import Models.Diagram as DiagramModel
import Models.Model exposing (Model, Msg(..), Notification(..), Settings, ShareUrl(..))
import Parser
import Route exposing (Route(..), toRoute)
import Settings exposing (settingsDecoder)
import String
import Subscriptions exposing (decodeShareText, downloadPng, downloadSvg, editSettings, encodeShareText, errorLine, layoutEditor, loadEditor, loadText, saveSettings, selectLine, subscriptions)
import Task
import Url as Url exposing (percentDecode)
import Utils
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
    in
    changeRouteTo (toRoute url)
        { diagramModel = Diagram.init settings.storyMap
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
        , isEditSettings = False
        , notification = Nothing
        , url = url
        , key = key
        , tabIndex = 1
        , progress = True
        , apiConfig =
            { apiRoot = apiRoot
            }
        , isExporting = False
        }


view : Model -> Html Msg
view model =
    main_
        [ style "position" "relative"
        , style "width" "100vw"
        , style "height" "100vh"
        , onClick CloseMenu
        ]
        [ lazy3 Header.view model.title model.isEditTitle model.window.fullscreen
        , case model.notification of
            Just notification ->
                Notification.view notification

            Nothing ->
                div [] []
        , if model.progress then
            ProgressBar.view

          else
            div [] []
        , if model.isExporting then
            ProgressBar.view

          else
            div [] []
        , let
            window =
                if Utils.isPhone model.diagramModel.width then
                    lazy4 Tab.view
                        model.diagramModel.settings.backgroundColor
                        model.tabIndex

                else
                    lazy4 SplitWindow.view
                        model.diagramModel.settings.backgroundColor
                        model.window

            indentButton =
                if Utils.isPhone model.diagramModel.width then
                    div
                        [ style "width"
                            "44px"
                        , style
                            "height"
                            "44px"
                        , style "position" "fixed"
                        , style "right" "0"
                        , style "bottom" "60px"
                        , style "background-color" "#282C32"
                        , style "color" "#FFFFFF"
                        , style "border-top-left-radius" "4px"
                        , style "border-bottom-left-radius" "4px"
                        , style "display" "flex"
                        , style "align-items" "center"
                        , style "justify-content" "center"
                        , onClick Indent
                        ]
                        [ Icon.indent 20
                        ]

                else
                    div [] []
          in
          div
            [ class "main" ]
            [ lazy4 Menu.view model.diagramModel.width model.window.fullscreen model.isEditSettings model.openMenu
            , if model.diagramModel.width == 0 then
                div [] []

              else
                window
                    (lazy Editor.view model.isEditSettings)
                    (if String.isEmpty model.text then
                        Logo.view

                     else
                        lazy Diagram.view model.diagramModel
                            |> Html.map UpdateDiagram
                    )
            , indentButton
            ]
        ]


main : Program ( String, Settings ) Model Msg
main =
    Browser.application
        { init = init
        , update = update
        , view =
            \m ->
                { title =
                    case m.title of
                        Just t ->
                            t ++ " | TextUSM"

                        Nothing ->
                            "untitled | TextUSM"
                , body = [ view m ]
                }
        , subscriptions = subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }



-- Update


changeRouteTo : Route -> Model -> ( Model, Cmd Msg )
changeRouteTo route model =
    case route of
        Route.CallbackTrello (Just token) (Just code) ->
            let
                usm =
                    Diagram.update (DiagramModel.OnChangeText model.text) model.diagramModel

                req =
                    Api.createRequest token
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

                apiConfig =
                    { apiRoot = model.apiConfig.apiRoot
                    }
            in
            ( { model
                | apiConfig = apiConfig
                , isExporting = True
              }
            , Cmd.batch
                [ Task.perform Init Dom.getViewport
                , Task.perform identity (Task.succeed (OnNotification (Info "Start export to Trello." Nothing)))
                , Task.attempt Exported (Api.export apiConfig Api.Trello req)
                ]
            )

        Route.Share diagram title path ->
            let
                diagramModel =
                    model.diagramModel

                newDiagramModel =
                    { diagramModel
                        | diagramType =
                            case diagram of
                                "usm" ->
                                    DiagramModel.UserStoryMap

                                "bmc" ->
                                    DiagramModel.BusinessModelCanvas

                                "opc" ->
                                    DiagramModel.OpportunityCanvas

                                _ ->
                                    DiagramModel.UserStoryMap
                    }
            in
            ( { model
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
            , Cmd.batch
                [ decodeShareText path
                , Task.perform Init Dom.getViewport
                ]
            )

        Route.UsmView settingsJson ->
            changeRouteTo (Route.View "usm" settingsJson) model

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
                            case diagram of
                                "usm" ->
                                    DiagramModel.UserStoryMap

                                "bmc" ->
                                    DiagramModel.BusinessModelCanvas

                                "opc" ->
                                    DiagramModel.OpportunityCanvas

                                _ ->
                                    DiagramModel.UserStoryMap
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
                    ( { model
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
                    , Task.perform Init Dom.getViewport
                    )

                Nothing ->
                    ( model, Task.perform Init Dom.getViewport )

        Route.BusinessModelCanvas ->
            let
                diagramModel =
                    model.diagramModel

                newDiagramModel =
                    { diagramModel | diagramType = DiagramModel.BusinessModelCanvas }
            in
            ( { model | diagramModel = newDiagramModel }
            , Task.perform Init Dom.getViewport
            )

        Route.OpportunityCanvas ->
            let
                diagramModel =
                    model.diagramModel

                newDiagramModel =
                    { diagramModel | diagramType = DiagramModel.OpportunityCanvas }
            in
            ( { model | diagramModel = newDiagramModel }
            , Task.perform Init Dom.getViewport
            )

        _ ->
            let
                diagramModel =
                    model.diagramModel

                newDiagramModel =
                    { diagramModel | diagramType = DiagramModel.UserStoryMap }
            in
            ( { model | diagramModel = newDiagramModel }
            , Task.perform Init Dom.getViewport
            )


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        NoOp ->
            ( model, Cmd.none )

        UpdateDiagram subMsg ->
            case subMsg of
                DiagramModel.ItemClick item ->
                    ( model, selectLine item.text )

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

        DownloadPng ->
            let
                width =
                    Basics.max model.diagramModel.svg.width model.diagramModel.width

                height =
                    case model.diagramModel.diagramType of
                        DiagramModel.BusinessModelCanvas ->
                            1000

                        _ ->
                            Basics.max model.diagramModel.svg.height model.diagramModel.height
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
                        DiagramModel.BusinessModelCanvas ->
                            1000

                        _ ->
                            Basics.max model.diagramModel.svg.height model.diagramModel.height
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
            ( model, Cmd.batch [ Task.perform identity (Task.succeed (UpdateDiagram (DiagramModel.OnChangeText text))), loadText ( text, False ) ] )

        SaveToLocal ->
            let
                title =
                    model.title |> Maybe.withDefault ""
            in
            ( model, Download.string title "text/plain" model.text )

        SelectLine line ->
            ( model, selectLine line )

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

        ToggleSettings ->
            ( { model | isEditSettings = not model.isEditSettings }
            , Cmd.batch
                [ editSettings model.settings
                , if model.isEditSettings then
                    layoutEditor 100

                  else
                    Cmd.none
                ]
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
                    currentSettings =
                        model.settings

                    settings =
                        { currentSettings
                            | text = Just model.text
                            , title =
                                model.title
                            , position = Just model.window.position
                        }
                in
                ( { model | settings = settings }
                , saveSettings settings
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

        OnShareUrl ->
            ( model
            , encodeShareText
                { diagramType =
                    case model.diagramModel.diagramType of
                        DiagramModel.UserStoryMap ->
                            "usm"

                        DiagramModel.OpportunityCanvas ->
                            "opc"

                        DiagramModel.BusinessModelCanvas ->
                            "bmc"
                , title = model.title
                , text = model.text
                }
            )

        OnNotification notification ->
            ( { model | notification = Just notification }, Cmd.none )

        OnAutoCloseNotification notification ->
            ( { model | notification = Just notification }, Utils.delay 3000 OnCloseNotification )

        OnCloseNotification ->
            ( { model | notification = Nothing }, Cmd.none )

        OnEncodeShareText path ->
            ( { model | share = Just (ShareUrl path) }, Cmd.none )

        OnDecodeShareText text ->
            ( model, Task.perform identity (Task.succeed (FileLoaded text)) )

        TabSelect tab ->
            ( { model | tabIndex = tab }, layoutEditor 100 )

        Indent ->
            let
                newText =
                    model.text ++ Constants.inputPrefix
            in
            ( { model | text = newText }, loadText ( newText, True ) )

        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        UrlChanged url ->
            changeRouteTo (toRoute url) model

        GetAccessTokenForTrello ->
            ( model, Api.getAccessToken model.apiConfig Api.Trello )

        Exported (Err e) ->
            ( { model | isExporting = False }
            , Cmd.batch
                [ Task.perform identity (Task.succeed (OnNotification (Error ("Error export. " ++ Api.errorToString e))))
                , Nav.pushUrl model.key "/"
                ]
            )

        Exported (Ok result) ->
            let
                messageCmd =
                    if result.failed > 0 then
                        Task.perform identity
                            (Task.succeed (OnNotification (Warning "Finish export, but some errors occurred. Click to open Trello." (Just result.url))))

                    else
                        Task.perform identity
                            (Task.succeed (OnNotification (Info "Finish export. Click to open Trello." (Just result.url))))
            in
            ( { model | isExporting = False }
            , Cmd.batch
                [ messageCmd
                , Nav.pushUrl model.key "/"
                ]
            )

        DoOpenUrl url ->
            ( model, Nav.load url )

        ExportGithub ->
            let
                req =
                    Maybe.map
                        (\g ->
                            Api.createRequest
                                g.token
                                Nothing
                                (Just
                                    { owner = g.owner
                                    , repo = g.repo
                                    }
                                )
                                model.diagramModel.hierarchy
                                (Parser.parseComment model.text)
                                (if model.title == Just "" then
                                    "UnTitled"

                                 else
                                    model.title |> Maybe.withDefault "UnTitled"
                                )
                                model.diagramModel.items
                        )
                        model.settings.github

                apiConfig =
                    { apiRoot = model.apiConfig.apiRoot
                    }
            in
            ( { model
                | apiConfig = apiConfig
                , isExporting = isJust req
              }
            , case req of
                Just r ->
                    Cmd.batch
                        [ Task.perform identity (Task.succeed (OnNotification (Info "Start export to Github." Nothing)))
                        , Task.attempt Exported (Api.export apiConfig Api.Github r)
                        ]

                Nothing ->
                    Cmd.batch
                        [ Task.perform identity (Task.succeed (OnNotification (Warning "Invalid settings. Please add github.owner, github.repo and github.token to settings." Nothing)))
                        , Task.perform identity (Task.succeed ToggleSettings)
                        ]
            )

        NewUserStoryMap ->
            ( model, Nav.pushUrl model.key "/" )

        NewBusinessModelCanvas ->
            let
                text =
                    if model.text == "" then
                        "👥 Key Partners\n📊 Customer Segments\n🎁 Value Proposition\n✅ Key Activities\n🚚 Channels\n💰 Revenue Streams\n🏷️ Cost Structure\n💪 Key Resources\n💙 Customer Relationships"

                    else
                        model.text
            in
            ( { model
                | text = text
              }
            , Cmd.batch [ loadText ( text, False ), Nav.pushUrl model.key "/bmc", Task.perform identity (Task.succeed (UpdateDiagram (DiagramModel.OnChangeText text))) ]
            )

        NewOpportunityCanvas ->
            let
                text =
                    if model.text == "" then
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

                    else
                        model.text
            in
            ( { model
                | text = text
              }
            , Cmd.batch [ loadText ( text, False ), Nav.pushUrl model.key "/opc", Task.perform identity (Task.succeed (UpdateDiagram (DiagramModel.OnChangeText text))) ]
            )
