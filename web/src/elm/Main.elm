module Main exposing (init, main, view)

import Action
import Api.RequestError as RequestError
import Asset
import Browser
import Browser.Events
    exposing
        ( Visibility(..)
        , onMouseMove
        , onMouseUp
        , onResize
        , onVisibilityChange
        )
import Browser.Navigation as Nav
import Components.Diagram as Diagram
import Dialog.Confirm as ConfirmDialog
import Dialog.Input as InputDialog
import Dialog.Share as Share
import Env
import File.Download as Download
import Graphql.Enum.Diagram as Diagram
import Html exposing (Html, div, img, main_, text)
import Html.Attributes exposing (alt, attribute, class, id, style)
import Html.Events as E
import Html.Lazy as Lazy
import Json.Decode as D
import Json.Encode as E
import Maybe.Extra exposing (isJust)
import Message
import Models.Diagram as DiagramModel
import Models.Diagram.ER as ER
import Models.Diagram.Table as Table
import Models.DiagramId as DiagramId
import Models.DiagramItem as DiagramItem
import Models.DiagramLocation as DiagramLocation
import Models.DiagramType as DiagramType
import Models.Dialog as Dialog
import Models.FileType as FileType
import Models.IdToken as IdToken
import Models.Jwt as Jwt
import Models.LoginProvider as LoginProdiver
import Models.Model as Model exposing (Model, Msg(..), Notification(..), SwitchWindow(..))
import Models.Page as Page
import Models.Session as Session
import Models.ShareToken as ShareToken
import Models.Size as Size
import Models.Text as Text
import Models.Title as Title
import Page.Embed as Embed
import Page.Help as Help
import Page.List as DiagramList
import Page.New as New
import Page.NotFound as NotFound
import Page.Settings as Settings
import Ports
import RemoteData exposing (RemoteData(..))
import Return as Return exposing (Return)
import Route exposing (Route(..), toRoute)
import Settings
    exposing
        ( defaultEditorSettings
        , defaultSettings
        , settingsDecoder
        , settingsEncoder
        )
import String
import Task
import Time
import Url
import Utils.Diagram as DiagramUtils
import Utils.Utils as Utils
import Views.Empty as Empty
import Views.Footer as Footer
import Views.Header as Header
import Views.Loading as Loading
import Views.Menu as Menu
import Views.Notification as Notification
import Views.ProgressBar as ProgressBar
import Views.SplitWindow as SplitWindow
import Views.SwitchWindow as SwitchWindow


type alias Flags =
    { lang : String
    , settings : D.Value
    , isOnline : Bool
    , isDarkMode : Bool
    }


init : Flags -> Url.Url -> Nav.Key -> Return Msg Model
init flags url key =
    let
        initSettings =
            D.decodeValue settingsDecoder flags.settings
                |> Result.withDefault (defaultSettings flags.isDarkMode)

        lang =
            Message.fromString flags.lang

        ( diagramListModel, _ ) =
            DiagramList.init Session.guest lang Env.apiRoot flags.isOnline

        ( diagramModel, _ ) =
            Diagram.init initSettings.storyMap

        ( shareModel, _ ) =
            Share.init
                { diagram = Diagram.UserStoryMap
                , diagramId = DiagramId.fromString ""
                , session = Session.guest
                , title = Title.untitled
                }

        ( settingsModel, _ ) =
            Settings.init Session.guest initSettings

        model =
            { diagramModel = { diagramModel | text = Text.fromString (Maybe.withDefault "" initSettings.text) }
            , diagramListModel = diagramListModel
            , settingsModel = settingsModel
            , shareModel = shareModel
            , openMenu = Nothing
            , title = Title.fromString (Maybe.withDefault "" initSettings.title)
            , window =
                { position = initSettings.position |> Maybe.withDefault 0
                , moveStart = False
                , moveX = 0
                , fullscreen = False
                , showEditor = True
                }
            , notification = Nothing
            , url = url
            , key = key
            , switchWindow = Left
            , progress = False
            , session = Session.guest
            , currentDiagram = initSettings.diagram
            , page = Page.Main
            , lang = lang
            , confirmDialog = Dialog.Hide
            , prevRoute = Nothing
            , view =
                { password = Nothing
                , authenticated = False
                , token = Nothing
                , error = Nothing
                }
            , isOnline = flags.isOnline
            , isDarkMode = flags.isDarkMode
            }
    in
    Return.singleton model |> changeRouteTo (toRoute url)


editor : Model -> Html Msg
editor model =
    div [ id "editor", class "full p-sm" ]
        [ Html.node "monaco-editor"
            [ attribute "value" <| Text.toString model.diagramModel.text
            , attribute "fontSize" <| String.fromInt <| .fontSize <| defaultEditorSettings model.settingsModel.settings.editor
            , attribute "wordWrap" <|
                if .wordWrap <| defaultEditorSettings model.settingsModel.settings.editor then
                    "true"

                else
                    "false"
            , attribute "showLineNumber" <|
                if .showLineNumber <| defaultEditorSettings model.settingsModel.settings.editor then
                    "true"

                else
                    "false"
            , attribute "changed" <|
                if Text.isChanged model.diagramModel.text then
                    "true"

                else
                    "false"
            ]
            []
        ]


view : Model -> Html Msg
view model =
    main_
        [ class "relative w-screen"
        , E.onClick CloseMenu
        ]
        [ Lazy.lazy Header.view
            { session = model.session
            , page = model.page
            , title = model.title
            , isFullscreen = model.window.fullscreen
            , currentDiagram = model.currentDiagram
            , menu = model.openMenu
            , currentText = model.diagramModel.text
            , lang = model.lang
            , route = toRoute model.url
            , prevRoute = model.prevRoute
            , isOnline = model.isOnline
            }
        , Lazy.lazy showNotification model.notification
        , Lazy.lazy showProgress model.progress
        , div
            [ class "flex"
            , class "overflow-hidden"
            , class "relative"
            , class "w-full"
            , if model.window.fullscreen then
                class "h-screen"

              else
                class "h-content"
            ]
            [ Lazy.lazy Menu.view
                { page = model.page
                , route = toRoute model.url
                , text = model.diagramModel.text
                , width = Size.getWidth model.diagramModel.size
                , fullscreen = model.window.fullscreen
                , openMenu = model.openMenu
                , lang = model.lang
                }
            , let
                mainWindow =
                    if Size.getWidth model.diagramModel.size > 0 && Utils.isPhone (Size.getWidth model.diagramModel.size) then
                        Lazy.lazy5 SwitchWindow.view
                            SwitchWindow
                            model.diagramModel.settings.backgroundColor
                            model.switchWindow
                            (div
                                [ class "h-main"
                                , class "bg-main"
                                , class "lg:h-full"
                                , class "w-full"
                                ]
                                [ editor model
                                ]
                            )

                    else
                        Lazy.lazy3 SplitWindow.view
                            { onResize = HandleStartWindowResize
                            , onToggleEditor = ShowEditor
                            , showEditor = model.window.showEditor
                            , backgroundColor = model.diagramModel.settings.backgroundColor
                            , window = model.window
                            }
                            (div
                                [ class "bg-main"
                                , class "w-full"
                                , class "h-main"
                                , class "lg:h-full"
                                ]
                                [ editor model
                                ]
                            )
              in
              case model.page of
                Page.List ->
                    Lazy.lazy DiagramList.view model.diagramListModel |> Html.map UpdateDiagramList

                Page.Help ->
                    Help.view

                Page.Settings ->
                    Lazy.lazy Settings.view model.settingsModel |> Html.map UpdateSettings

                Page.Embed _ _ _ ->
                    Embed.view model

                Page.New ->
                    New.view

                Page.NotFound ->
                    NotFound.view

                _ ->
                    case toRoute model.url of
                        ViewFile _ id_ ->
                            case ShareToken.unwrap id_ |> Maybe.andThen Jwt.fromString of
                                Just jwt ->
                                    if jwt.checkEmail && Session.isGuest model.session then
                                        div
                                            [ class "flex-center"
                                            , class "text-xl"
                                            , class "font-semibold"
                                            , class "w-screen"
                                            , class "text-color"
                                            , class "m-sm"
                                            , class "text-sm"
                                            , style "height" "calc(100vh - 40px)"
                                            ]
                                            [ img [ class "keyframe anim", Asset.src Asset.logo, style "width" "32px", alt "NOT FOUND" ] []
                                            , div [ class "m-sm" ] [ text "Sign in required" ]
                                            ]

                                    else
                                        div [ class "full", style "background-color" model.settingsModel.settings.storyMap.backgroundColor ]
                                            [ Lazy.lazy Diagram.view model.diagramModel
                                                |> Html.map UpdateDiagram
                                            ]

                                Nothing ->
                                    NotFound.view

                        _ ->
                            mainWindow
                                (Lazy.lazy Diagram.view model.diagramModel
                                    |> Html.map UpdateDiagram
                                )
            ]
        , case toRoute model.url of
            Share ->
                Lazy.lazy Share.view model.shareModel |> Html.map UpdateShare

            ViewFile _ id_ ->
                case ShareToken.unwrap id_ |> Maybe.andThen Jwt.fromString of
                    Just jwt ->
                        if jwt.checkPassword && not model.view.authenticated then
                            Lazy.lazy InputDialog.view
                                { title = "Protedted diagram"
                                , errorMessage = Maybe.map RequestError.toMessage model.view.error
                                , value = model.view.password |> Maybe.withDefault ""
                                , inProcess = model.progress
                                , lang = model.lang
                                , onInput = EditPassword
                                , onEnter = EndEditPassword
                                }

                        else
                            Empty.view

                    Nothing ->
                        Empty.view

            _ ->
                Empty.view
        , Lazy.lazy showDialog model.confirmDialog
        , Footer.view
        ]


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , update = \msg m -> Return.singleton m |> update msg
        , view =
            \m ->
                { title =
                    Title.toString m.title
                        ++ (if Text.isChanged m.diagramModel.text then
                                "*"

                            else
                                ""
                           )
                        ++ " | TextUSM"
                , body = [ view m ]
                }
        , subscriptions = subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }


showProgress : Bool -> Html Msg
showProgress show =
    if show then
        div [ class "absolute top-0 left-0 full-screen z-40 flex-center", style "background-color" "rgba(39,48,55,0.4)" ] [ ProgressBar.view, Loading.view ]

    else
        Empty.view


showNotification : Maybe Notification -> Html Msg
showNotification notify =
    Notification.view notify


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



-- Update


changeRouteTo : Route -> Return.ReturnF Msg Model
changeRouteTo route =
    case route of
        Route.DiagramList ->
            Return.andThen Action.initListPage
                >> Return.andThen (Action.switchPage Page.List)
                >> Return.andThen Action.startProgress

        Route.New ->
            Return.andThen <| Action.switchPage Page.New

        Route.NotFound ->
            Return.andThen <| Action.switchPage Page.NotFound

        Route.Embed diagram title id_ width height ->
            Return.andThen
                (\m ->
                    Return.singleton
                        { m
                            | window = m.window |> Model.windowOfFullscreen.set True
                            , diagramModel =
                                m.diagramModel
                                    |> DiagramModel.modelOfShowZoomControl.set False
                                    |> DiagramModel.modelOfDiagramType.set diagram
                                    |> DiagramModel.modelOfScale.set 1.0
                        }
                )
                >> Return.andThen (Action.setTitle title)
                >> Return.andThen (Action.loadShareItem id_)
                >> Return.andThen
                    (Action.switchPage
                        (Page.Embed diagram
                            title
                            (Maybe.andThen (\w -> Maybe.andThen (\h -> Just ( w, h )) height) width)
                        )
                    )
                >> Return.andThen Action.changeRouteInit

        Route.Edit diagramType ->
            let
                diagram =
                    { id = Nothing
                    , text = Text.fromString <| DiagramType.defaultText diagramType
                    , diagram = diagramType
                    , title = Title.untitled
                    , thumbnail = Nothing
                    , isPublic = False
                    , isBookmark = False
                    , isRemote = False
                    , location = Just DiagramLocation.Local
                    , createdAt = Time.millisToPosix 0
                    , updatedAt = Time.millisToPosix 0
                    }
            in
            Return.andThen (Action.setCurrentDiagram (Just diagram))
                >> Return.andThen Action.loadSettings
                >> Return.andThen
                    (\m ->
                        Action.loadDiagram diagram m
                    )
                >> Return.andThen (Action.switchPage Page.Main)
                >> Return.andThen Action.changeRouteInit

        Route.EditLocalFile _ id_ ->
            Return.andThen (Action.switchPage Page.Main)
                >> Return.andThen (Action.loadLocalDiagram id_)
                >> Return.andThen Action.changeRouteInit

        Route.EditFile _ id_ ->
            Return.andThen
                (\m ->
                    Return.singleton m
                        |> (if Session.isSignedIn m.session && m.isOnline then
                                Return.andThen Action.updateIdToken
                                    >> Return.andThen (Action.switchPage Page.Main)
                                    >> Return.andThen Action.loadSettings
                                    >> Return.andThen (Action.loadItem id_)

                            else
                                Return.andThen (Action.switchPage Page.Main)
                                    >> Return.andThen (Action.loadLocalDiagram id_)
                                    >> Return.andThen Action.changeRouteInit
                           )
                )

        Route.ViewPublic _ id_ ->
            Return.andThen Action.updateIdToken
                >> Return.andThen (Action.switchPage Page.Main)
                >> Return.andThen (Action.loadPublicItem id_)

        Route.Home ->
            Return.andThen (Action.switchPage Page.Main)
                >> Return.andThen Action.redirectToLastEditedFile
                >> Return.andThen Action.changeRouteInit

        Route.Settings ->
            Return.andThen Action.initSettingsPage
                >> Return.andThen (Action.switchPage Page.Settings)

        Route.Help ->
            Return.andThen <| Action.switchPage Page.Help

        Route.Share ->
            Return.andThen
                (\m ->
                    case ( m.currentDiagram, Session.isSignedIn m.session ) of
                        ( Just diagram, True ) ->
                            Return.singleton m
                                |> (if diagram.isRemote then
                                        Return.andThen (Action.initShareDiagram diagram)
                                            >> Return.andThen Action.startProgress

                                    else
                                        Return.andThen <| Action.moveTo Route.Home
                                   )

                        _ ->
                            Action.moveTo Route.Home m
                )

        Route.ViewFile _ id_ ->
            case ShareToken.unwrap id_ |> Maybe.andThen Jwt.fromString of
                Just jwt ->
                    Return.andThen (Action.setShareToken id_)
                        >> (if jwt.checkPassword || jwt.checkEmail then
                                Return.andThen (Action.switchPage Page.Main)
                                    >> Return.andThen Action.changeRouteInit

                            else
                                Return.andThen (Action.switchPage Page.Main)
                                    >> Return.andThen (Action.loadShareItem id_)
                                    >> Return.andThen Action.startProgress
                                    >> Return.andThen Action.changeRouteInit
                           )

                Nothing ->
                    Return.andThen <| Action.switchPage Page.NotFound


update : Msg -> Return.ReturnF Msg Model
update message =
    case message of
        NoOp ->
            Return.zero

        UpdateShare msg ->
            Return.andThen
                (\m ->
                    case toRoute m.url of
                        Share ->
                            let
                                ( model_, cmd_ ) =
                                    Share.update msg m.shareModel
                            in
                            Return.return { m | shareModel = model_ } (cmd_ |> Cmd.map UpdateShare)
                                |> (case msg of
                                        Share.Shared (Err e) ->
                                            Return.andThen <| Action.showErrorMessage e

                                        Share.Close ->
                                            Action.historyBack m.key

                                        Share.LoadShareCondition (Err e) ->
                                            Return.andThen <| Action.showErrorMessage e

                                        _ ->
                                            Return.zero
                                   )
                                >> Return.andThen Action.stopProgress

                        _ ->
                            Return.singleton m
                )

        UpdateSettings msg ->
            Return.andThen
                (\m ->
                    let
                        ( model_, cmd_ ) =
                            Return.singleton m.settingsModel |> Settings.update msg
                    in
                    Return.return
                        { m
                            | page = Page.Settings
                            , diagramModel = m.diagramModel |> DiagramModel.modelOfSettings.set model_.settings.storyMap
                            , settingsModel = model_
                        }
                        (cmd_ |> Cmd.map UpdateSettings)
                )

        UpdateDiagram msg ->
            Return.andThen
                (\m ->
                    let
                        ( model_, cmd_ ) =
                            Diagram.update msg m.diagramModel
                    in
                    case msg of
                        DiagramModel.OnResize _ _ ->
                            Return.return { m | diagramModel = model_ } (cmd_ |> Cmd.map UpdateDiagram)

                        DiagramModel.EndEditSelectedItem _ ->
                            Return.singleton { m | diagramModel = model_ }

                        DiagramModel.FontStyleChanged _ ->
                            case m.diagramModel.selectedItem of
                                Just _ ->
                                    Return.return { m | diagramModel = model_ } (cmd_ |> Cmd.map UpdateDiagram)

                                Nothing ->
                                    Return.singleton m

                        DiagramModel.ColorChanged _ _ ->
                            case m.diagramModel.selectedItem of
                                Just _ ->
                                    Return.return { m | diagramModel = model_ } (cmd_ |> Cmd.map UpdateDiagram)

                                Nothing ->
                                    Return.singleton m

                        DiagramModel.FontSizeChanged _ ->
                            case m.diagramModel.selectedItem of
                                Just _ ->
                                    Return.return { m | diagramModel = model_ } (cmd_ |> Cmd.map UpdateDiagram)

                                Nothing ->
                                    Return.singleton m

                        DiagramModel.ToggleFullscreen ->
                            Return.return
                                { m
                                    | window = m.window |> Model.windowOfFullscreen.set (not m.window.fullscreen)
                                    , diagramModel = model_
                                }
                                (cmd_ |> Cmd.map UpdateDiagram)
                                |> (if not m.window.fullscreen then
                                        Action.openFullscreen

                                    else
                                        Action.closeFullscreen
                                   )

                        _ ->
                            Return.return { m | diagramModel = model_ } (cmd_ |> Cmd.map UpdateDiagram)
                )

        UpdateDiagramList subMsg ->
            Return.andThen
                (\m ->
                    let
                        ( model_, cmd_ ) =
                            Return.singleton m.diagramListModel |> DiagramList.update subMsg
                    in
                    case subMsg of
                        DiagramList.Select diagram ->
                            case diagram.id of
                                Just _ ->
                                    (case ( diagram.isRemote, diagram.isPublic ) of
                                        ( True, True ) ->
                                            Action.pushUrl
                                                (Route.toString <|
                                                    ViewPublic diagram.diagram (DiagramItem.getId diagram)
                                                )
                                                m

                                        ( True, False ) ->
                                            Action.pushUrl
                                                (Route.toString <|
                                                    EditFile diagram.diagram (DiagramItem.getId diagram)
                                                )
                                                m

                                        _ ->
                                            Action.pushUrl
                                                (Route.toString <|
                                                    EditLocalFile diagram.diagram (DiagramItem.getId diagram)
                                                )
                                                m
                                    )
                                        |> Return.andThen Action.startProgress

                                Nothing ->
                                    Return.singleton m

                        DiagramList.Removed (Err _) ->
                            Action.showErrorMessage Message.messagEerrorOccurred m

                        DiagramList.GotDiagrams (Err _) ->
                            Action.showErrorMessage Message.messagEerrorOccurred m

                        DiagramList.ImportComplete json ->
                            case DiagramItem.stringToList json of
                                Ok _ ->
                                    Return.return { m | diagramListModel = model_ } (cmd_ |> Cmd.map UpdateDiagramList)
                                        |> Return.andThen (Action.showInfoMessage Message.messageImportCompleted)

                                Err _ ->
                                    Action.showErrorMessage Message.messagEerrorOccurred m

                        _ ->
                            Return.return { m | diagramListModel = model_ } (cmd_ |> Cmd.map UpdateDiagramList)
                                |> Return.andThen Action.stopProgress
                )

        Init window ->
            Return.andThen
                (\m ->
                    let
                        ( model_, cmd_ ) =
                            Diagram.update (DiagramModel.Init m.diagramModel.settings window (Text.toString m.diagramModel.text)) m.diagramModel

                        model__ =
                            case toRoute m.url of
                                Route.Embed _ _ _ (Just w) (Just h) ->
                                    let
                                        scale =
                                            toFloat w
                                                / toFloat model_.svg.width
                                    in
                                    { model_ | size = ( w, h ), svg = { width = w, height = h, scale = scale } }

                                _ ->
                                    model_
                    in
                    Return.return { m | diagramModel = model__ } (cmd_ |> Cmd.map UpdateDiagram)
                        |> Return.andThen (Action.loadText (m.currentDiagram |> Maybe.withDefault DiagramItem.empty))
                )
                >> Return.andThen Action.stopProgress

        DownloadCompleted ( x, y ) ->
            Return.andThen (\m -> Return.singleton { m | diagramModel = m.diagramModel |> DiagramModel.modelOfPosition.set ( x, y ) })

        Download fileType ->
            Return.andThen
                (\m ->
                    case fileType of
                        FileType.Ddl ex ->
                            let
                                ( _, tables ) =
                                    ER.from m.diagramModel.items

                                ddl =
                                    List.map ER.tableToString tables
                                        |> String.join "\n"
                            in
                            Return.return m <| Download.string (Title.toString m.title ++ ex) "text/plain" ddl

                        FileType.Markdown ex ->
                            Return.return m <| Download.string (Title.toString m.title ++ ex) "text/plain" (Table.toString (Table.from m.diagramModel.items))

                        FileType.PlainText ex ->
                            Return.return m <| Download.string (Title.toString m.title ++ ex) "text/plain" (Text.toString m.diagramModel.text)

                        _ ->
                            let
                                ( posX, posY ) =
                                    m.diagramModel.position

                                ( width, height ) =
                                    DiagramUtils.getCanvasSize m.diagramModel
                                        |> Tuple.mapBoth (\x -> x + posX) (\y -> y + posY)

                                ( download, extension ) =
                                    case fileType of
                                        FileType.Png ex ->
                                            ( Ports.downloadPng, ex )

                                        FileType.Pdf ex ->
                                            ( Ports.downloadPdf, ex )

                                        FileType.Svg ex ->
                                            ( Ports.downloadSvg, ex )

                                        FileType.Html ex ->
                                            ( Ports.downloadHtml, ex )

                                        _ ->
                                            ( Ports.downloadSvg, "" )
                            in
                            Return.return m <|
                                download
                                    { width = width
                                    , height = height
                                    , id = "usm"
                                    , title = Title.toString m.title ++ extension
                                    , x = 0
                                    , y = 0
                                    , text = Text.toString m.diagramModel.text
                                    , diagramType = DiagramType.toString m.diagramModel.diagramType
                                    }
                )

        StartDownload info ->
            Return.andThen (\m -> Return.return m (Download.string (Title.toString m.title ++ info.extension) info.mimeType info.content))
                >> Return.andThen Action.closeMenu

        OpenMenu menu ->
            Return.andThen <| \m -> Return.singleton { m | openMenu = Just menu }

        CloseMenu ->
            Return.andThen Action.closeMenu

        GotGithubAccessToken { cmd, accessToken } ->
            Return.andThen (\m -> Return.singleton { m | session = Session.updateAccessToken m.session (accessToken |> Maybe.withDefault "") })
                >> (if cmd == "save" then
                        Return.command (Task.perform identity (Task.succeed Save))

                    else
                        Return.andThen (Action.loadItem (DiagramId.fromString cmd))
                   )

        Save ->
            Return.andThen
                (\m ->
                    if Title.isUntitled m.title then
                        Action.startEditTitle m

                    else
                        let
                            location =
                                if Maybe.andThen .id m.currentDiagram |> isJust then
                                    Maybe.andThen .location m.currentDiagram

                                else
                                    m.settingsModel.settings.location
                        in
                        case ( location, Session.getAccessToken m.session ) of
                            ( Just DiagramLocation.Gist, Nothing ) ->
                                Return.return m <| Ports.getGithubAccessToken "save"

                            _ ->
                                let
                                    isRemote =
                                        m.currentDiagram
                                            |> Maybe.withDefault DiagramItem.empty
                                            |> DiagramItem.isRemoteDiagram m.session

                                    newDiagramModel =
                                        DiagramModel.updatedText m.diagramModel (Text.saved m.diagramModel.text)
                                in
                                Return.singleton
                                    { m
                                        | diagramListModel = m.diagramListModel |> DiagramList.modelOfDiagramList.set DiagramList.notAsked
                                        , diagramModel = newDiagramModel
                                    }
                                    |> Action.saveDiagram
                                        { id = Maybe.andThen .id m.currentDiagram
                                        , title = m.title
                                        , text = newDiagramModel.text
                                        , thumbnail = Nothing
                                        , diagram = newDiagramModel.diagramType
                                        , isRemote = isRemote
                                        , location =
                                            case Maybe.andThen .location m.currentDiagram of
                                                Just loc ->
                                                    Just loc

                                                Nothing ->
                                                    if isRemote then
                                                        Just DiagramLocation.Remote

                                                    else
                                                        Just DiagramLocation.Local
                                        , isPublic = Maybe.map .isPublic m.currentDiagram |> Maybe.withDefault False
                                        , isBookmark = False
                                        , updatedAt = Time.millisToPosix 0
                                        , createdAt = Time.millisToPosix 0
                                        }
                )

        SaveToLocalCompleted diagramJson ->
            case D.decodeValue DiagramItem.decoder diagramJson of
                Ok item ->
                    Return.andThen
                        (\m ->
                            Return.return { m | currentDiagram = Just item } <|
                                Route.replaceRoute m.key <|
                                    Route.EditLocalFile item.diagram
                                        (Maybe.withDefault (DiagramId.fromString "") <| item.id)
                        )
                        >> Return.andThen (Action.showInfoMessage Message.messageSuccessfullySaved)

                Err _ ->
                    Return.zero

        SaveToRemote diagramJson ->
            let
                result =
                    D.decodeValue DiagramItem.decoder diagramJson
            in
            case result of
                Ok diagram ->
                    Return.andThen (Action.saveToRemote diagram)
                        >> Return.andThen Action.startProgress

                Err _ ->
                    Return.andThen (Action.showWarningMessage Message.messageSuccessfullySaved)
                        >> Return.andThen Action.stopProgress

        SaveToRemoteCompleted (Err _) ->
            Return.andThen
                (\m ->
                    let
                        item =
                            { id = Nothing
                            , title = m.title
                            , text = m.diagramModel.text
                            , thumbnail = Nothing
                            , diagram = m.diagramModel.diagramType
                            , isRemote = False
                            , isPublic = False
                            , isBookmark = False
                            , location = Just DiagramLocation.Local
                            , updatedAt = Time.millisToPosix 0
                            , createdAt = Time.millisToPosix 0
                            }
                    in
                    Action.setCurrentDiagram (Just item) m
                        |> Action.saveToLocal item
                )
                >> Return.andThen Action.stopProgress
                >> Return.andThen (Action.showWarningMessage <| Message.messageFailedSaved)

        SaveToRemoteCompleted (Ok diagram) ->
            Return.andThen (Action.setCurrentDiagram <| Just diagram)
                >> Return.andThen
                    (\m ->
                        Return.return m <|
                            Route.replaceRoute m.key
                                (Route.EditFile diagram.diagram
                                    (diagram.id |> Maybe.withDefault (DiagramId.fromString ""))
                                )
                    )
                >> Return.andThen Action.stopProgress
                >> Return.andThen (Action.showInfoMessage <| Message.messageSuccessfullySaved)

        Shortcuts x ->
            case x of
                "save" ->
                    Return.andThen
                        (\m ->
                            if Text.isChanged m.diagramModel.text then
                                Return.return m <| Task.perform identity <| Task.succeed Save

                            else
                                Return.singleton m
                        )

                "open" ->
                    Return.andThen
                        (\m ->
                            Return.return m <| Nav.load <| Route.toString (toRoute m.url)
                        )

                _ ->
                    Return.zero

        StartEditTitle ->
            Return.andThen (\m -> Return.singleton { m | title = Title.edit m.title })
                >> Return.andThen (Action.setFocus "title")

        EndEditTitle ->
            Return.andThen (\m -> Return.singleton { m | title = Title.view m.title })
                >> Action.setFocusEditor

        EditTitle title ->
            Return.andThen (\m -> Return.singleton { m | title = Title.edit <| Title.fromString title })
                >> Return.andThen Action.needSaved

        HandleVisibilityChange visible ->
            case visible of
                Hidden ->
                    Return.andThen
                        (\m ->
                            if Session.isSignedIn m.session then
                                let
                                    newStoryMap =
                                        m.settingsModel.settings |> Settings.settingsOfFont.set m.settingsModel.settings.font

                                    newSettings =
                                        { position = Just m.window.position
                                        , font = m.settingsModel.settings.font
                                        , diagramId = Maybe.andThen (\d -> Maybe.andThen (\i -> Just <| DiagramId.toString i) d.id) m.currentDiagram
                                        , storyMap = newStoryMap.storyMap |> DiagramModel.settingsOfScale.set (Just m.diagramModel.svg.scale)
                                        , text = Just (Text.toString m.diagramModel.text)
                                        , title = Just <| Title.toString m.title
                                        , editor = m.settingsModel.settings.editor
                                        , diagram = m.currentDiagram
                                        , location = m.settingsModel.settings.location
                                        }

                                    ( newSettingsModel, _ ) =
                                        Settings.init m.session newSettings
                                in
                                Return.singleton { m | settingsModel = newSettingsModel }
                                    |> Return.command (Ports.saveSettings (settingsEncoder newSettings))

                            else
                                Return.singleton m
                        )

                _ ->
                    Return.zero

        HandleStartWindowResize x ->
            Return.andThen <|
                \m ->
                    Return.singleton
                        { m
                            | window =
                                m.window
                                    |> Model.windowOfMoveStart.set True
                                    |> Model.windowOfMoveX.set x
                        }

        MoveStop ->
            Return.andThen <| \m -> Return.singleton { m | window = m.window |> Model.windowOfMoveStart.set False }

        HandleWindowResize x ->
            Return.andThen <| \m -> Return.singleton { m | window = { position = m.window.position + x - m.window.moveX, moveStart = True, moveX = x, fullscreen = m.window.fullscreen, showEditor = m.window.showEditor } }

        ShowNotification notification ->
            Return.andThen <| \m -> Return.singleton { m | notification = Just notification }

        HandleAutoCloseNotification notification ->
            Return.andThen (\m -> Return.singleton { m | notification = Just notification })
                >> Action.closeNotification

        HandleCloseNotification ->
            Return.andThen <| \m -> Return.singleton { m | notification = Nothing }

        SwitchWindow w ->
            Return.andThen <| \m -> Return.singleton { m | switchWindow = w }

        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    Return.andThen
                        (\m ->
                            if Text.isChanged m.diagramModel.text && not (Dialog.display m.confirmDialog) then
                                Action.showConfirmDialog "Confirmation" "Your data has been changed. do you wish to continue?" (toRoute url) m

                            else
                                Action.pushUrl (Url.toString url) m
                                    |> Return.andThen Action.saveSettings
                        )

                Browser.External href ->
                    Return.command (Nav.load href)

        UrlChanged url ->
            Return.andThen
                (\m ->
                    Return.singleton { m | url = url, prevRoute = Just <| toRoute m.url } |> changeRouteTo (toRoute url)
                )

        SignIn provider ->
            Return.command (Ports.signIn <| LoginProdiver.toString provider)
                >> Return.andThen Action.startProgress

        SignOut ->
            Return.andThen Action.revokeGistToken
                >> Return.andThen (\m -> Return.return { m | session = Session.guest } (Ports.signOut ()))
                >> Return.andThen (Action.setCurrentDiagram Nothing)

        HandleAuthStateChanged (Just value) ->
            case D.decodeValue Session.decoder value of
                Ok user ->
                    Return.andThen (\m -> Return.singleton { m | session = Session.signIn user })
                        >> Return.andThen
                            (\m ->
                                case ( toRoute m.url, m.currentDiagram ) of
                                    ( Route.EditFile type_ id_, Just diagram ) ->
                                        if DiagramItem.getId diagram /= id_ then
                                            Action.pushUrl (Route.toString <| Route.EditFile type_ id_) m

                                        else
                                            Return.singleton m

                                    ( Route.EditFile type_ id_, _ ) ->
                                        Action.pushUrl (Route.toString <| Route.EditFile type_ id_) m

                                    ( Route.ViewFile _ id_, _ ) ->
                                        case ShareToken.unwrap id_ |> Maybe.andThen Jwt.fromString of
                                            Just jwt ->
                                                if jwt.checkPassword then
                                                    Action.switchPage Page.Main m
                                                        |> Return.andThen Action.changeRouteInit

                                                else
                                                    Action.switchPage Page.Main m
                                                        |> Return.andThen (Action.loadShareItem id_)
                                                        |> Return.andThen Action.startProgress
                                                        |> Return.andThen Action.changeRouteInit

                                            Nothing ->
                                                Action.switchPage Page.NotFound m

                                    ( Route.DiagramList, _ ) ->
                                        Action.pushUrl (Route.toString <| Route.Home) m

                                    _ ->
                                        Return.singleton m
                            )
                        >> Return.andThen Action.stopProgress

                Err _ ->
                    Return.andThen (\m -> Return.singleton { m | session = Session.guest })
                        >> Return.andThen Action.stopProgress

        HandleAuthStateChanged Nothing ->
            Return.andThen (\m -> Return.singleton { m | session = Session.guest })
                >> Return.andThen (Action.moveTo Route.Home)
                >> Return.andThen Action.stopProgress

        Progress visible ->
            Return.andThen <| \m -> Return.singleton { m | progress = visible }

        Load (Ok diagram) ->
            Return.andThen <| Action.loadDiagram diagram

        EditText text ->
            Return.andThen
                (\m ->
                    let
                        ( model_, cmd_ ) =
                            Diagram.update (DiagramModel.OnChangeText text) m.diagramModel
                    in
                    Return.return { m | diagramModel = model_ } (cmd_ |> Cmd.map UpdateDiagram)
                )

        Load (Err e) ->
            (case e of
                RequestError.NotFound ->
                    Return.andThen <| Action.moveTo Route.NotFound

                _ ->
                    Return.andThen <| Action.moveTo Route.Home
            )
                >> Return.andThen Action.stopProgress
                >> Return.andThen (Action.showErrorMessage <| RequestError.toMessage e)

        GotLocalDiagramJson json ->
            case D.decodeValue DiagramItem.decoder json of
                Ok item ->
                    Return.andThen <| Action.loadText item

                Err _ ->
                    Return.zero

        ChangePublicStatus isPublic ->
            Return.andThen
                (\m ->
                    case m.currentDiagram of
                        Just diagram ->
                            Action.updateIdToken m
                                |> Return.andThen (Action.changePublicState diagram isPublic)
                                |> Return.andThen Action.stopProgress

                        _ ->
                            Return.singleton m
                )

        ChangePublicStatusCompleted (Ok d) ->
            Return.andThen (Action.setCurrentDiagram <| Just d)
                >> Return.andThen Action.stopProgress
                >> Return.andThen (Action.showInfoMessage Message.messagePublished)

        ChangePublicStatusCompleted (Err _) ->
            Return.andThen (Action.showErrorMessage Message.messageFailedPublished)
                >> Return.andThen Action.stopProgress

        CloseFullscreen _ ->
            Return.andThen
                (\m ->
                    let
                        ( model_, cmd_ ) =
                            Diagram.update DiagramModel.ToggleFullscreen m.diagramModel
                    in
                    Return.return { m | window = m.window |> Model.windowOfFullscreen.set False, diagramModel = model_ } (cmd_ |> Cmd.map UpdateDiagram)
                )

        UpdateIdToken token ->
            Return.andThen <| \m -> Return.singleton { m | session = Session.updateIdToken m.session (IdToken.fromString token) }

        MoveTo route ->
            Return.andThen Action.unchanged
                >> Return.andThen Action.saveSettings
                >> Return.andThen Action.closeDialog
                >> Return.andThen (Action.moveTo route)

        EditPassword password ->
            Return.andThen <|
                \m ->
                    Return.singleton { m | view = { password = Just password, authenticated = False, token = m.view.token, error = Nothing } }

        EndEditPassword ->
            Return.andThen
                (\m ->
                    case m.view.token of
                        Just token ->
                            Action.switchPage Page.Main m
                                |> Return.andThen (Action.loadWithPasswordShareItem token)
                                |> Return.andThen Action.startProgress

                        Nothing ->
                            Return.singleton m
                )

        LoadWithPassword (Ok diagram) ->
            Return.andThen Action.canView
                >> Return.andThen (Action.loadDiagram diagram)

        LoadWithPassword (Err e) ->
            Return.andThen (Action.canNotView e)
                >> Return.andThen Action.stopProgress

        CloseDialog ->
            Return.andThen Action.closeDialog

        CallApi (Ok ()) ->
            Return.zero

        CallApi (Err m) ->
            Return.andThen (Action.showErrorMessage m)

        LoadSettings (Ok settings) ->
            Return.andThen Action.stopProgress
                >> Return.andThen (Action.setSettings settings)

        LoadSettings (Err _) ->
            Return.andThen (\m -> Action.setSettings (.storyMap (Settings.defaultSettings m.isDarkMode)) m)
                >> Return.andThen Action.stopProgress

        SaveSettings (Ok _) ->
            Return.andThen Action.stopProgress

        SaveSettings (Err _) ->
            Return.andThen (Action.showWarningMessage Message.messageFailedSaveSettings)
                >> Return.andThen Action.stopProgress

        ChangeNetworkState isOnline ->
            Return.andThen <| \m -> Return.singleton { m | isOnline = isOnline }

        ShowEditor show ->
            Return.andThen <| \m -> Return.singleton { m | window = m.window |> Model.windowOfShowEditor.set show }



-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        ([ Ports.changeText (\text -> UpdateDiagram (DiagramModel.OnChangeText text))
         , Ports.startDownload StartDownload
         , Ports.gotLocalDiagramsJson (\json -> UpdateDiagramList (DiagramList.GotLocalDiagramsJson json))
         , Ports.reload (\_ -> UpdateDiagramList DiagramList.Reload)
         , onVisibilityChange HandleVisibilityChange
         , onResize (\width height -> UpdateDiagram (DiagramModel.OnResize width height))
         , Ports.shortcuts Shortcuts
         , Ports.onNotification (\n -> HandleAutoCloseNotification (Info n))
         , Ports.sendErrorNotification (\n -> HandleAutoCloseNotification (Error n))
         , Ports.onWarnNotification (\n -> HandleAutoCloseNotification (Warning n))
         , Ports.onAuthStateChanged HandleAuthStateChanged
         , Ports.saveToRemote SaveToRemote
         , Ports.removeRemoteDiagram (\diagram -> UpdateDiagramList <| DiagramList.RemoveRemote diagram)
         , Ports.downloadCompleted DownloadCompleted
         , Ports.progress Progress
         , Ports.saveToLocalCompleted SaveToLocalCompleted
         , Ports.gotLocalDiagramJson GotLocalDiagramJson
         , Ports.onCloseFullscreen CloseFullscreen
         , Ports.updateIdToken UpdateIdToken
         , Ports.gotGithubAccessToken GotGithubAccessToken
         , Ports.changeNetworkState ChangeNetworkState
         ]
            ++ (if model.window.moveStart then
                    [ onMouseUp <| D.succeed MoveStop
                    , onMouseMove <| D.map HandleWindowResize (D.field "pageX" D.int)
                    ]

                else
                    [ Sub.none ]
               )
        )
