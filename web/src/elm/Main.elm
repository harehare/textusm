module Main exposing (Flags, main)

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
import Css exposing (backgroundColor, calc, displayFlex, height, hex, hidden, minus, overflow, position, px, relative, vh, width)
import Dialog.Confirm as ConfirmDialog
import Dialog.Input as InputDialog
import Dialog.Share as Share
import Env
import File.Download as Download
import Html.Styled as Html exposing (Html, div, img, main_, text)
import Html.Styled.Attributes exposing (alt, attribute, css, id)
import Html.Styled.Events as E
import Html.Styled.Lazy as Lazy
import Json.Decode as D
import Message exposing (Message)
import Models.Diagram as DiagramModel
import Models.DiagramId as DiagramId
import Models.DiagramItem as DiagramItem exposing (DiagramItem)
import Models.DiagramLocation as DiagramLocation exposing (DiagramLocation)
import Models.DiagramSettings as DiagramSettings
import Models.DiagramType as DiagramType exposing (DiagramType(..))
import Models.Dialog as Dialog
import Models.Exporter as Exporter
import Models.IdToken as IdToken
import Models.Jwt as Jwt
import Models.LoginProvider as LoginProdiver
import Models.Model as Model exposing (Model, Msg(..))
import Models.Notification as Notification
import Models.Page as Page exposing (Page)
import Models.Session as Session
import Models.SettingsCache as SettingsCache
import Models.ShareState as ShareState
import Models.ShareToken as ShareToken
import Models.Shortcuts as Shortcuts
import Models.Size as Size exposing (Size)
import Models.Snackbar as SnackbarModel
import Models.Text as Text
import Models.Title as Title
import Models.Window as Window exposing (Window)
import Page.Embed as Embed
import Page.Help as Help
import Page.List as DiagramList
import Page.New as New
import Page.NotFound as NotFound
import Page.Settings as Settings
import Ports
import Return exposing (Return)
import Route exposing (Route(..), toRoute)
import Settings
    exposing
        ( Settings
        , defaultEditorSettings
        , defaultSettings
        , settingsDecoder
        , settingsEncoder
        )
import String
import Style.Breakpoint as Breakpoint
import Style.Color as ColorStyle
import Style.Font as FontStyle
import Style.Global as GlobalStyle
import Style.Style as Style
import Style.Text as TextStyle
import Task
import Time
import Url
import Utils.Utils as Utils
import Views.Empty as Empty
import Views.Footer as Footer
import Views.Header as Header
import Views.Menu as Menu
import Views.Notification as Notification
import Views.Progress as Progress
import Views.Snackbar as Snackbar
import Views.SplitWindow as SplitWindow
import Views.SwitchWindow as SwitchWindow
import Attributes


type alias Flags =
    { lang : String
    , settings : D.Value
    , isOnline : Bool
    , isDarkMode : Bool
    , canUseNativeFileSystem : Bool
    }


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        , subscriptions = subscriptions
        , update = \msg m -> Return.singleton m |> update msg
        , view =
            \m ->
                { title =
                    Title.toString m.currentDiagram.title
                        ++ (if Text.isChanged m.diagramModel.text then
                                "*"

                            else
                                ""
                           )
                        ++ " | TextUSM"
                , body = [ Html.toUnstyled <| view m ]
                }
        }


changeRouteTo : Route -> Return.ReturnF Msg Model
changeRouteTo route =
    case route of
        Route.Home ->
            Return.andThen (switchPage Page.Main)
                >> Return.andThen redirectToLastEditedFile
                >> Action.changeRouteInit Init

        Route.New ->
            Return.andThen <| switchPage Page.New

        Route.Edit diagramType ->
            let
                diagram : DiagramItem
                diagram =
                    DiagramItem.new diagramType
            in
            Return.andThen (setCurrentDiagram diagram)
                >> Return.andThen startProgress
                >> Return.andThen (\m -> Return.singleton m |> Action.loadSettings LoadSettings { cache = m.settingsCache, diagramType = m.currentDiagram.diagram, session = m.session })
                >> Return.andThen (loadDiagram diagram)
                >> Return.andThen (switchPage Page.Main)
                >> Action.changeRouteInit Init
                >> Action.closeLocalFile

        Route.EditFile _ id_ ->
            Return.andThen
                (\m ->
                    Return.singleton m
                        |> (if Session.isSignedIn m.session && m.browserStatus.isOnline then
                                Action.updateIdToken
                                    >> Return.andThen (switchPage Page.Main)
                                    >> Return.andThen startProgress
                                    >> Action.loadItem Load { id = id_, session = m.session }

                            else
                                Return.andThen (switchPage Page.Main)
                                    >> Action.loadLocalDiagram id_
                                    >> Action.changeRouteInit Init
                           )
                        >> Action.loadSettings LoadSettings { cache = m.settingsCache, diagramType = m.currentDiagram.diagram, session = m.session }
                )

        Route.EditLocalFile _ id_ ->
            Return.andThen (switchPage Page.Main)
                >> Action.loadLocalDiagram id_
                >> Action.changeRouteInit Init

        Route.ViewPublic _ id_ ->
            Action.updateIdToken
                >> Return.andThen (switchPage Page.Main)
                >> Return.andThen (\m -> Return.singleton m |> Action.loadPublicItem Load { id = id_, session = m.session })

        Route.DiagramList ->
            Return.andThen initListPage
                >> Return.andThen (switchPage Page.List)
                >> Return.andThen startProgress

        Route.Settings diagramType ->
            Return.andThen (initSettingsPage diagramType)
                >> Return.andThen (switchPage Page.Settings)

        Route.Help ->
            Return.andThen <| switchPage Page.Help

        Route.Share ->
            Return.andThen
                (\m ->
                    if Session.isSignedIn m.session && m.currentDiagram.isRemote then
                        Return.singleton m
                            |> Return.andThen (initShareDiagram m.currentDiagram)
                            >> Return.andThen startProgress

                    else
                        moveTo Route.Home m
                )

        Route.Embed diagram title id_ width height ->
            Return.andThen
                (\m ->
                    Return.singleton
                        { m
                            | diagramModel =
                                m.diagramModel
                                    |> DiagramModel.ofShowZoomControl.set False
                                    |> DiagramModel.ofDiagramType.set diagram
                                    |> DiagramModel.ofScale.set 1.0
                                    |> DiagramModel.ofSize.set
                                        ( Maybe.withDefault (Size.getWidth m.diagramModel.size) width
                                        , Maybe.withDefault (Size.getHeight m.diagramModel.size) height
                                        )
                            , window = m.window |> Window.fullscreen
                        }
                )
                >> Return.andThen (setTitle title)
                >> Return.andThen (\m -> Return.singleton m |> Action.loadShareItem Load { session = m.session, token = id_ })
                >> Return.andThen (switchPage Page.Embed)
                >> Action.changeRouteInit Init

        Route.ViewFile _ id_ ->
            case ShareToken.unwrap id_ |> Maybe.andThen Jwt.fromString of
                Just jwt ->
                    if jwt.checkPassword || jwt.checkEmail then
                        Return.andThen
                            (\m ->
                                Return.singleton
                                    { m | shareState = ShareState.authenticateWithPassword id_ }
                            )
                            >> Return.andThen (switchPage Page.Main)
                            >> Action.changeRouteInit Init

                    else
                        Return.andThen
                            (\m ->
                                Return.singleton
                                    { m | shareState = ShareState.authenticateNoPassword id_ }
                                    |> Action.loadShareItem Load { session = m.session, token = id_ }
                            )
                            >> Return.andThen (switchPage Page.Main)
                            >> Return.andThen startProgress
                            >> Action.changeRouteInit Init

                Nothing ->
                    Return.andThen <| switchPage Page.NotFound

        Route.NotFound ->
            Return.andThen <| switchPage Page.NotFound


editor : Model -> Html Msg
editor model =
    let
        editorSettings : Settings.EditorSettings
        editorSettings =
            defaultEditorSettings model.settingsModel.settings.editor
    in
    div [ id "editor", css [ Style.full, Style.paddingSm ] ]
        [ Html.node "monaco-editor"
            [ attribute "value" <| Text.toString model.diagramModel.text
            , attribute "fontSize" <| String.fromInt <| .fontSize <| defaultEditorSettings model.settingsModel.settings.editor
            , attribute "wordWrap" <|
                if editorSettings.wordWrap then
                    "true"

                else
                    "false"
            , attribute "showLineNumber" <|
                if editorSettings.showLineNumber then
                    "true"

                else
                    "false"
            , attribute "changed" <|
                if Text.isChanged model.diagramModel.text then
                    "true"

                else
                    "false"
            , attribute "diagramType" <| DiagramType.toTypeString model.currentDiagram.diagram
            , Attributes.dataTest "editor"
            ]
            []
        ]


init : Flags -> Url.Url -> Nav.Key -> Return Msg Model
init flags url key =
    let
        currentDiagram : DiagramItem
        currentDiagram =
            initSettings.diagram |> Maybe.withDefault DiagramItem.empty

        ( diagramListModel, _ ) =
            DiagramList.init Session.guest lang Env.apiRoot flags.isOnline

        ( diagramModel, _ ) =
            Diagram.init initSettings.storyMap

        initSettings : Settings
        initSettings =
            D.decodeValue settingsDecoder flags.settings
                |> Result.withDefault (defaultSettings flags.isDarkMode)

        lang : Message.Lang
        lang =
            Message.fromString flags.lang

        model : Model
        model =
            { key = key
            , url = url
            , page = Page.Main
            , diagramModel = { diagramModel | text = Text.fromString (Maybe.withDefault "" initSettings.text) }
            , diagramListModel = diagramListModel
            , settingsModel = settingsModel
            , shareModel = shareModel
            , session = Session.guest
            , currentDiagram = { currentDiagram | title = Title.fromString (Maybe.withDefault "" initSettings.title) }
            , openMenu = Nothing
            , window = Window.init <| Maybe.withDefault 0 initSettings.position
            , progress = False
            , lang = lang
            , prevRoute = Nothing
            , shareState = ShareState.unauthorized
            , browserStatus =
                { isOnline = flags.isOnline
                , isDarkMode = flags.isDarkMode
                , canUseNativeFileSystem = flags.canUseNativeFileSystem
                }
            , confirmDialog = Dialog.Hide
            , snackbar = SnackbarModel.Hide
            , notification = Notification.Hide
            , settingsCache = SettingsCache.new
            }

        ( settingsModel, _ ) =
            Settings.init
                { canUseNativeFileSystem = flags.canUseNativeFileSystem
                , diagramType = currentDiagram.diagram
                , session = Session.guest
                , settings = initSettings
                }

        ( shareModel, _ ) =
            Share.init
                { diagram = UserStoryMap
                , diagramId = DiagramId.fromString ""
                , session = Session.guest
                , title = Title.untitled
                }
    in
    Return.singleton model |> changeRouteTo (toRoute url)


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


showProgress : Bool -> Html Msg
showProgress show =
    if show then
        Progress.view

    else
        Empty.view



-- Return


setCurrentDiagram : DiagramItem -> Model -> Return Msg Model
setCurrentDiagram currentDiagram model =
    Return.singleton { model | currentDiagram = currentDiagram }


moveTo : Route -> Model -> Return Msg Model
moveTo route model =
    Return.return model <| Route.moveTo model.key route


needSaved : Model -> Return Msg Model
needSaved model =
    Return.singleton
        { model
            | diagramModel =
                model.diagramModel
                    |> DiagramModel.ofText.set (Text.change model.diagramModel.text)
        }


pushUrl : String -> Model -> Return Msg Model
pushUrl url model =
    Return.return model <| Nav.pushUrl model.key url


redirectToLastEditedFile : Model -> Return Msg Model
redirectToLastEditedFile model =
    case ( model.currentDiagram.id, model.currentDiagram.diagram ) of
        ( Just id_, diagramType ) ->
            moveTo (Route.EditFile diagramType id_) model

        _ ->
            Return.singleton model


startProgress : Model -> Return Msg Model
startProgress model =
    Return.singleton { model | progress = True }


stopProgress : Model -> Return Msg Model
stopProgress model =
    Return.singleton { model | progress = False }


switchPage : Page -> Model -> Return Msg Model
switchPage page model =
    Return.singleton { model | page = page }


closeDialog : Model -> Return Msg Model
closeDialog model =
    Return.singleton { model | confirmDialog = Dialog.Hide }


closeMenu : Model -> Return Msg Model
closeMenu model =
    Return.singleton { model | openMenu = Nothing }


initListPage : Model -> Return Msg Model
initListPage model =
    let
        ( model_, cmd_ ) =
            DiagramList.init model.session model.lang model.diagramListModel.apiRoot model.browserStatus.isOnline
    in
    Return.return { model | diagramListModel = model_ } (cmd_ |> Cmd.map UpdateDiagramList)


initSettingsPage : DiagramType -> Model -> Return Msg Model
initSettingsPage diagramType model =
    let
        ( model_, cmd_ ) =
            Settings.init
                { canUseNativeFileSystem = model.browserStatus.canUseNativeFileSystem
                , diagramType = diagramType
                , session = model.session
                , settings = model.settingsModel.settings
                }
    in
    Return.return { model | settingsModel = model_ } (cmd_ |> Cmd.map UpdateSettings)


initShareDiagram : DiagramItem -> Model -> Return Msg Model
initShareDiagram diagramItem model =
    let
        ( shareModel, cmd_ ) =
            Share.init
                { diagram = diagramItem.diagram
                , diagramId = diagramItem.id |> Maybe.withDefault (DiagramId.fromString "")
                , session = model.session
                , title = model.currentDiagram.title
                }
    in
    Return.return { model | shareModel = shareModel } (cmd_ |> Cmd.map UpdateShare)


closeNotification : Return.ReturnF Msg Model
closeNotification =
    Return.command (Utils.delay 3000 HandleCloseNotification)


showErrorMessage : Message -> Model -> Return Msg Model
showErrorMessage msg model =
    Return.return model
        (Notification.showErrorNotifcation (msg model.lang)
            |> ShowNotification
            |> Task.succeed
            |> Task.perform identity
        )
        |> closeNotification


showInfoMessage : Message -> Model -> Return Msg Model
showInfoMessage msg model =
    Return.return model
        (Notification.showInfoNotifcation (msg model.lang)
            |> ShowNotification
            |> Task.succeed
            |> Task.perform identity
        )
        |> closeNotification


showWarningMessage : Message -> Model -> Return Msg Model
showWarningMessage msg model =
    Return.return model
        (Notification.showWarningNotifcation (msg model.lang)
            |> ShowNotification
            |> Task.succeed
            |> Task.perform identity
        )
        |> closeNotification


loadDiagram : DiagramItem -> Model -> Return Msg Model
loadDiagram diagram model =
    let
        ( model_, cmd_ ) =
            Return.singleton newDiagramModel |> Diagram.update (DiagramModel.ChangeText <| Text.toString diagram.text)

        diagramModel : DiagramModel.Model
        diagramModel =
            model.diagramModel

        newDiagramModel : DiagramModel.Model
        newDiagramModel =
            { diagramModel
                | diagramType = diagram.diagram
                , text = diagram.text
            }
    in
    Return.return
        { model
            | diagramModel = model_
            , currentDiagram = diagram
        }
        (cmd_ |> Cmd.map UpdateDiagram)
        |> Return.andThen stopProgress


setDiagramSettings : DiagramSettings.Settings -> Model -> Return Msg Model
setDiagramSettings settings model =
    let
        newSettings : Settings.Model
        newSettings =
            model.settingsModel
    in
    Return.singleton
        { model
            | diagramModel = model.diagramModel |> DiagramModel.ofSettings.set settings
            , settingsModel = { newSettings | settings = model.settingsModel.settings |> Settings.storyMapOfSettings.set settings }
        }
        |> Return.andThen (setDiagramSettingsCache settings)


setDiagramSettingsCache : DiagramSettings.Settings -> Model -> Return Msg Model
setDiagramSettingsCache settings model =
    Return.singleton
        { model | settingsCache = SettingsCache.set model.settingsCache model.currentDiagram.diagram settings }


updateWindowState : Model -> Return Msg Model
updateWindowState model =
    Return.singleton
        { model
            | window =
                model.window
                    |> (if Utils.isPhone (Size.getWidth model.diagramModel.size) then
                            Window.showEditor

                        else if Window.isFullscreen model.window then
                            Window.fullscreen

                        else
                            Window.showEditorAndPreview
                       )
        }


unchanged : Model -> Return Msg Model
unchanged model =
    Return.singleton
        { model
            | diagramModel =
                model.diagramModel
                    |> DiagramModel.ofText.set (Text.saved model.diagramModel.text)
        }


setTitle : String -> Model -> Return Msg Model
setTitle title model =
    Return.singleton { model | currentDiagram = DiagramItem.ofTitle.set (Title.fromString <| title) model.currentDiagram }


showConfirmDialog : String -> String -> Route -> Model -> Return Msg Model
showConfirmDialog title message route model =
    Return.singleton
        { model
            | confirmDialog = Dialog.Show { title = title, message = message, ok = MoveTo route, cancel = CloseDialog }
        }


startEditTitle : Model -> Return Msg Model
startEditTitle model =
    Return.return model <| Task.perform identity <| Task.succeed StartEditTitle



-- Update


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        ([ Ports.changeText (\text -> UpdateDiagram (DiagramModel.ChangeText text))
         , Ports.loadSettingsFromLocalCompleted LoadSettingsFromLocal
         , Ports.startDownload StartDownload
         , Ports.gotLocalDiagramsJson (\json -> UpdateDiagramList (DiagramList.GotLocalDiagramsJson json))
         , Ports.reload (\_ -> UpdateDiagramList DiagramList.Reload)
         , onVisibilityChange HandleVisibilityChange
         , onResize (\width height -> UpdateDiagram (DiagramModel.Resize width height))
         , Ports.shortcuts (\cmd -> Shortcuts <| Shortcuts.fromString cmd)
         , Ports.onNotification (\n -> HandleAutoCloseNotification (Notification.showInfoNotifcation n))
         , Ports.sendErrorNotification (\n -> HandleAutoCloseNotification (Notification.showErrorNotifcation n))
         , Ports.onWarnNotification (\n -> HandleAutoCloseNotification (Notification.showWarningNotifcation n))
         , Ports.onAuthStateChanged HandleAuthStateChanged
         , Ports.saveToRemote SaveToRemote
         , Ports.removeRemoteDiagram (\diagram -> UpdateDiagramList <| DiagramList.RemoveRemote diagram)
         , Ports.downloadCompleted DownloadCompleted
         , Ports.progress Progress
         , Ports.saveToLocalCompleted SaveToLocalCompleted
         , Ports.gotLocalDiagramJson GotLocalDiagramJson
         , Ports.fullscreen <|
            \f ->
                if f then
                    NoOp

                else
                    CloseFullscreen
         , Ports.updateIdToken UpdateIdToken
         , Ports.gotGithubAccessToken GotGithubAccessToken
         , Ports.changeNetworkState ChangeNetworkState
         , Ports.notifyNewVersionAvailable NotifyNewVersionAvailable
         , Ports.openedLocalFile OpenedLocalFile
         , Ports.savedLocalFile SavedLocalFile
         ]
            ++ (if Window.isResizing model.window then
                    [ onMouseUp <| D.succeed MoveStop
                    , onMouseMove <| D.map HandleWindowResize (D.field "pageX" D.int)
                    ]

                else
                    [ Sub.none ]
               )
        )


update : Msg -> Return.ReturnF Msg Model
update message =
    case message of
        NoOp ->
            Return.zero

        Init window ->
            Return.andThen
                (\m ->
                    let
                        ( model_, cmd_ ) =
                            Return.singleton m.diagramModel |> Diagram.update (DiagramModel.Init m.diagramModel.settings window (Text.toString m.diagramModel.text))

                        newModel : DiagramModel.Model
                        newModel =
                            case toRoute m.url of
                                Route.Embed _ _ _ (Just w) (Just h) ->
                                    let
                                        scale : Float
                                        scale =
                                            toFloat w
                                                / toFloat (Size.getWidth model_.svg.size)
                                    in
                                    { model_ | size = ( w, h ), svg = { size = ( w, h ), scale = scale } }

                                _ ->
                                    model_
                    in
                    Return.return { m | diagramModel = newModel } (cmd_ |> Cmd.map UpdateDiagram)
                        |> Action.loadText Load m.currentDiagram
                        |> Return.andThen updateWindowState
                )
                >> Return.andThen stopProgress

        UpdateDiagram msg ->
            Return.andThen
                (\m ->
                    let
                        ( model_, cmd_ ) =
                            Return.singleton m.diagramModel |> Diagram.update msg
                    in
                    Return.return { m | diagramModel = model_ } (cmd_ |> Cmd.map UpdateDiagram)
                        |> (case msg of
                                DiagramModel.ToggleFullscreen ->
                                    Return.andThen
                                        (\m_ ->
                                            Return.singleton { m_ | window = windowState m_.window model_.isFullscreen model_.size }
                                                |> Action.toggleFullscreen m_.window
                                        )

                                DiagramModel.Resize _ _ ->
                                    Return.andThen updateWindowState

                                _ ->
                                    Return.zero
                           )
                )

        UpdateDiagramList subMsg ->
            Return.andThen
                (\m ->
                    let
                        ( model_, cmd_ ) =
                            Return.singleton m.diagramListModel |> DiagramList.update subMsg
                    in
                    Return.return { m | diagramListModel = model_ } (cmd_ |> Cmd.map UpdateDiagramList)
                )
                >> updateDiagramList subMsg

        UpdateShare msg ->
            Return.andThen
                (\m ->
                    let
                        ( model_, cmd_ ) =
                            Share.update msg m.shareModel
                    in
                    Return.return { m | shareModel = model_ } (cmd_ |> Cmd.map UpdateShare)
                        |> updateShare m msg
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
                            | diagramModel = m.diagramModel |> DiagramModel.ofSettings.set model_.settings.storyMap
                            , page = Page.Settings
                            , settingsModel = model_
                        }
                        (cmd_ |> Cmd.map UpdateSettings)
                        |> updateSettings msg model_.diagramType
                )

        OpenMenu menu ->
            Return.andThen <| \m -> Return.singleton { m | openMenu = Just menu }

        MoveStop ->
            Return.andThen <| \m -> Return.singleton { m | window = Window.resized m.window }

        CloseMenu ->
            Return.andThen closeMenu

        Copy ->
            Return.andThen (\m -> pushUrl (Route.toString <| Edit m.currentDiagram.diagram) m)
                >> Return.andThen startProgress
                >> Action.closeLocalFile
                >> Return.andThen (\m -> Return.return m <| Utils.delay 100 <| Copied <| DiagramItem.copy m.currentDiagram)

        Copied diagram ->
            Return.andThen <| loadDiagram diagram

        Download exportDiagram ->
            Return.andThen
                (\m ->
                    let
                        ( posX, posY ) =
                            m.diagramModel.position
                    in
                    Exporter.export
                        exportDiagram
                        { data = m.diagramModel.data
                        , diagramType = m.diagramModel.diagramType
                        , items = m.diagramModel.items
                        , size =
                            DiagramModel.size m.diagramModel
                                |> Tuple.mapBoth (\x -> x + posX) (\y -> y + posY)
                        , text = m.diagramModel.text
                        , title = m.currentDiagram.title
                        }
                        |> Maybe.map (\cmd -> Return.return m cmd)
                        |> Maybe.withDefault (Return.singleton m)
                )

        DownloadCompleted ( x, y ) ->
            Return.andThen (\m -> Return.singleton { m | diagramModel = m.diagramModel |> DiagramModel.ofPosition.set ( x, y ) })

        StartDownload info ->
            Return.andThen (\m -> Return.return m (Download.string (Title.toString m.currentDiagram.title ++ info.extension) info.mimeType info.content))
                >> Return.andThen closeMenu

        Save ->
            Return.andThen
                (\m ->
                    if Title.isUntitled m.currentDiagram.title then
                        startEditTitle m

                    else
                        let
                            location : Maybe DiagramLocation
                            location =
                                m.currentDiagram.id |> Maybe.map (\_ -> m.currentDiagram.location) |> Maybe.withDefault m.settingsModel.settings.location
                        in
                        case ( location, Session.isGithubUser m.session, Session.getAccessToken m.session ) of
                            ( Just DiagramLocation.Gist, True, Nothing ) ->
                                Return.return m <| Ports.getGithubAccessToken "save"

                            _ ->
                                let
                                    isRemote : Bool
                                    isRemote =
                                        m.currentDiagram
                                            |> DiagramItem.isRemoteDiagram m.session

                                    newDiagramModel : DiagramModel.Model
                                    newDiagramModel =
                                        DiagramModel.updatedText m.diagramModel (Text.saved m.diagramModel.text)
                                in
                                Return.singleton
                                    { m
                                        | diagramModel = newDiagramModel
                                        , diagramListModel = m.diagramListModel |> DiagramList.modelOfDiagramList.set DiagramList.notAsked
                                    }
                                    |> Action.saveDiagram
                                        { id = m.currentDiagram.id
                                        , text = newDiagramModel.text
                                        , diagram = newDiagramModel.diagramType
                                        , title = m.currentDiagram.title
                                        , thumbnail = Nothing
                                        , isPublic = m.currentDiagram.isPublic
                                        , isBookmark = False
                                        , isRemote = isRemote
                                        , location =
                                            case m.currentDiagram.location of
                                                Just loc ->
                                                    Just loc

                                                Nothing ->
                                                    if isRemote then
                                                        Just DiagramLocation.Remote

                                                    else
                                                        Just DiagramLocation.Local
                                        , createdAt = Time.millisToPosix 0
                                        , updatedAt = Time.millisToPosix 0
                                        }
                )

        SaveToRemoteCompleted (Ok diagram) ->
            Return.andThen (setCurrentDiagram diagram)
                >> Return.andThen
                    (\m ->
                        Return.return m <|
                            Route.replaceRoute m.key
                                (Route.EditFile diagram.diagram
                                    (diagram.id |> Maybe.withDefault (DiagramId.fromString ""))
                                )
                    )
                >> Return.andThen stopProgress
                >> Return.andThen (showInfoMessage <| Message.messageSuccessfullySaved)

        SaveToRemoteCompleted (Err _) ->
            Return.andThen
                (\m ->
                    let
                        item : DiagramItem
                        item =
                            { id = Nothing
                            , text = m.diagramModel.text
                            , diagram = m.diagramModel.diagramType
                            , title = m.currentDiagram.title
                            , thumbnail = Nothing
                            , isPublic = False
                            , isBookmark = False
                            , isRemote = False
                            , location = Just DiagramLocation.Local
                            , createdAt = Time.millisToPosix 0
                            , updatedAt = Time.millisToPosix 0
                            }
                    in
                    setCurrentDiagram item m
                        |> Action.saveToLocal item
                )
                >> Return.andThen stopProgress
                >> Return.andThen (showWarningMessage <| Message.messageFailedSaved)

        SaveToLocalCompleted diagramJson ->
            case D.decodeValue DiagramItem.decoder diagramJson of
                Ok item ->
                    Return.andThen
                        (\m ->
                            Return.return { m | currentDiagram = item } <|
                                Route.replaceRoute m.key <|
                                    Route.EditLocalFile item.diagram
                                        (Maybe.withDefault (DiagramId.fromString "") <| item.id)
                        )
                        >> Return.andThen (showInfoMessage Message.messageSuccessfullySaved)

                Err _ ->
                    Return.zero

        SaveToRemote diagramJson ->
            let
                result : Result D.Error DiagramItem
                result =
                    D.decodeValue DiagramItem.decoder diagramJson
            in
            case result of
                Ok diagram ->
                    Return.andThen
                        (\m ->
                            Return.singleton m
                                |> Action.saveToRemote SaveToRemoteCompleted { diagram = diagram, session = m.session, settings = m.settingsModel.settings }
                                >> Return.andThen startProgress
                        )

                Err _ ->
                    Return.andThen (showWarningMessage Message.messageSuccessfullySaved)
                        >> Return.andThen stopProgress

        StartEditTitle ->
            Return.andThen (\m -> Return.singleton { m | currentDiagram = DiagramItem.ofTitle.set (Title.edit m.currentDiagram.title) m.currentDiagram })
                >> Action.setFocus NoOp "title"

        Progress visible ->
            Return.andThen <| \m -> Return.singleton { m | progress = visible }

        EndEditTitle ->
            Return.andThen (\m -> Return.singleton { m | currentDiagram = DiagramItem.ofTitle.set (Title.view m.currentDiagram.title) m.currentDiagram })
                >> Action.setFocusEditor

        EditTitle title ->
            Return.andThen (\m -> Return.singleton { m | currentDiagram = DiagramItem.ofTitle.set (Title.edit <| Title.fromString title) m.currentDiagram })
                >> Return.andThen needSaved

        SignIn provider ->
            Return.command (Ports.signIn <| LoginProdiver.toString provider)
                >> Return.andThen startProgress

        SignOut ->
            Return.andThen
                (\m ->
                    Return.singleton { m | session = Session.guest }
                        |> Action.revokeGistToken CallApi m.session
                        |> Return.command (Ports.signOut ())
                )
                >> Return.andThen (setCurrentDiagram DiagramItem.empty)

        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    Return.andThen <|
                        \m ->
                            if Text.isChanged m.diagramModel.text && not (Dialog.display m.confirmDialog) then
                                showConfirmDialog "Confirmation" "Your data has been changed. do you wish to continue?" (toRoute url) m

                            else
                                case toRoute m.url of
                                    Route.Settings diagramType ->
                                        pushUrl (Url.toString url) m
                                            |> Action.saveSettings SaveSettings { session = m.session, diagramType = diagramType, settings = m.settingsModel.settings }
                                            |> Return.andThen (setDiagramSettingsCache m.settingsModel.settings.storyMap)

                                    _ ->
                                        pushUrl (Url.toString url) m

                Browser.External href ->
                    Return.command (Nav.load href)

        UrlChanged url ->
            Return.andThen <|
                \m ->
                    Return.singleton { m | url = url, prevRoute = Just <| toRoute m.url } |> changeRouteTo (toRoute url)

        HandleVisibilityChange visible ->
            case visible of
                Hidden ->
                    Return.andThen
                        (\m ->
                            let
                                newSettings : Settings
                                newSettings =
                                    { position = Just m.window.position
                                    , font = m.settingsModel.settings.font
                                    , diagramId = Maybe.map DiagramId.toString m.currentDiagram.id
                                    , storyMap = newStoryMap.storyMap |> DiagramSettings.ofScale.set (Just m.diagramModel.svg.scale)
                                    , text = Just (Text.toString m.diagramModel.text)
                                    , title = Just <| Title.toString m.currentDiagram.title
                                    , editor = m.settingsModel.settings.editor
                                    , diagram = Just m.currentDiagram
                                    , location = m.settingsModel.settings.location
                                    }

                                ( newSettingsModel, _ ) =
                                    Settings.init
                                        { canUseNativeFileSystem = m.browserStatus.canUseNativeFileSystem
                                        , diagramType = m.currentDiagram.diagram
                                        , session = m.session
                                        , settings = newSettings
                                        }

                                newStoryMap : Settings
                                newStoryMap =
                                    m.settingsModel.settings |> Settings.ofFont.set m.settingsModel.settings.font
                            in
                            Return.singleton { m | settingsModel = newSettingsModel }
                                |> Return.command (Ports.saveSettingsToLocal (settingsEncoder newSettings))
                        )

                _ ->
                    Return.zero

        HandleStartWindowResize x ->
            Return.andThen <| \m -> Return.singleton { m | window = Window.startResizing m.window x }

        HandleWindowResize x ->
            Return.andThen <| \m -> Return.singleton { m | window = Window.resizing m.window x }

        HandleAutoCloseNotification notification ->
            Return.andThen (\m -> Return.singleton { m | notification = notification })
                >> closeNotification

        HandleCloseNotification ->
            Return.andThen <| \m -> Return.singleton { m | notification = Notification.Hide }

        HandleAuthStateChanged (Just value) ->
            case D.decodeValue Session.decoder value of
                Ok user ->
                    Return.andThen (\m -> Return.singleton { m | session = Session.signIn user })
                        >> Return.andThen
                            (\m ->
                                case toRoute m.url of
                                    Route.EditFile type_ id_ ->
                                        if DiagramItem.getId m.currentDiagram /= id_ then
                                            pushUrl (Route.toString <| Route.EditFile type_ id_) m

                                        else
                                            Return.singleton m

                                    Route.DiagramList ->
                                        pushUrl (Route.toString <| Route.Home) m

                                    Route.ViewFile _ id_ ->
                                        case ShareToken.unwrap id_ |> Maybe.andThen Jwt.fromString of
                                            Just jwt ->
                                                if jwt.checkPassword then
                                                    switchPage Page.Main m
                                                        |> Action.changeRouteInit Init

                                                else
                                                    switchPage Page.Main m
                                                        |> Action.loadShareItem Load { session = m.session, token = id_ }
                                                        |> Return.andThen startProgress
                                                        |> Action.changeRouteInit Init

                                            Nothing ->
                                                switchPage Page.NotFound m

                                    _ ->
                                        Return.singleton m
                            )
                        >> Return.andThen stopProgress

                Err _ ->
                    Return.andThen (\m -> Return.singleton { m | session = Session.guest })
                        >> Return.andThen stopProgress

        HandleAuthStateChanged Nothing ->
            Return.andThen (\m -> Return.singleton { m | session = Session.guest })
                >> Return.andThen (moveTo Route.Home)
                >> Return.andThen stopProgress

        ShowNotification notification ->
            Return.andThen <| \m -> Return.singleton { m | notification = notification }

        SwitchWindow w ->
            Return.andThen <| \m -> Return.singleton { m | window = Window.toggle w }

        Shortcuts cmd ->
            case cmd of
                Just Shortcuts.Open ->
                    Return.andThen <|
                        \m ->
                            Return.return m <| Nav.load <| Route.toString (toRoute m.url)

                Just Shortcuts.Save ->
                    Return.andThen <|
                        \m ->
                            case ( m.settingsModel.settings.location, Text.isChanged m.diagramModel.text ) of
                                ( Just DiagramLocation.LocalFileSystem, True ) ->
                                    Return.return m <| Task.perform identity <| Task.succeed SaveLocalFile

                                ( _, True ) ->
                                    Return.return m <| Task.perform identity <| Task.succeed Save

                                _ ->
                                    Return.singleton m

                _ ->
                    Return.zero

        GotLocalDiagramJson json ->
            case D.decodeValue DiagramItem.decoder json of
                Ok item ->
                    Action.loadText Load item

                Err _ ->
                    Return.zero

        ChangePublicStatus isPublic ->
            Return.andThen <|
                \m ->
                    Return.singleton m
                        |> Action.updateIdToken
                        |> Action.changePublicState ChangePublicStatusCompleted { isPublic = isPublic, item = m.currentDiagram, session = m.session }
                        |> Return.andThen stopProgress

        ChangePublicStatusCompleted (Ok d) ->
            Return.andThen (setCurrentDiagram d)
                >> Return.andThen stopProgress
                >> Return.andThen (showInfoMessage Message.messagePublished)

        ChangePublicStatusCompleted (Err _) ->
            Return.andThen (showErrorMessage Message.messageFailedPublished)
                >> Return.andThen stopProgress

        Load (Ok diagram) ->
            Return.andThen <| loadDiagram diagram

        Load (Err e) ->
            (case e of
                RequestError.NotFound ->
                    Return.andThen <| moveTo Route.NotFound

                _ ->
                    Return.zero
            )
                >> Return.andThen stopProgress
                >> Return.andThen (showErrorMessage <| RequestError.toMessage e)

        LoadSettings (Ok settings) ->
            Return.andThen stopProgress
                >> Return.andThen (setDiagramSettings settings)

        LoadSettings (Err _) ->
            Return.andThen (\m -> setDiagramSettings (.storyMap (defaultSettings m.browserStatus.isDarkMode)) m)
                >> Return.andThen stopProgress

        LoadSettingsFromLocal settingsJson ->
            case D.decodeValue settingsDecoder settingsJson of
                Ok settings ->
                    Return.andThen
                        (\m ->
                            let
                                ( newSettingsModel, _ ) =
                                    Settings.init
                                        { canUseNativeFileSystem = m.browserStatus.canUseNativeFileSystem
                                        , diagramType = m.currentDiagram.diagram
                                        , session = m.session
                                        , settings = settings
                                        }
                            in
                            Return.singleton { m | settingsModel = newSettingsModel, diagramModel = DiagramModel.ofSettings.set settings.storyMap m.diagramModel }
                        )

                Err _ ->
                    Return.andThen (showWarningMessage Message.messageFailedLoadSettings)

        SaveSettings (Ok _) ->
            Return.andThen stopProgress

        SaveSettings (Err _) ->
            Return.andThen (showWarningMessage Message.messageFailedSaveSettings)
                >> Return.andThen stopProgress

        CallApi (Ok ()) ->
            Return.zero

        CallApi (Err m) ->
            Return.andThen (showErrorMessage m)

        CloseFullscreen ->
            Return.andThen <|
                \m ->
                    let
                        ( model_, cmd_ ) =
                            Return.singleton m.diagramModel |> Diagram.update DiagramModel.ToggleFullscreen
                    in
                    Return.return
                        { m
                            | diagramModel = model_
                            , window =
                                m.window
                                    |> (if Utils.isPhone (Size.getWidth m.diagramModel.size) then
                                            Window.showEditor

                                        else
                                            Window.showEditorAndPreview
                                       )
                        }
                        (cmd_ |> Cmd.map UpdateDiagram)

        UpdateIdToken token ->
            Return.andThen <| \m -> Return.singleton { m | session = Session.updateIdToken m.session (IdToken.fromString token) }

        EditPassword password ->
            Return.andThen <|
                \m ->
                    Return.singleton { m | shareState = ShareState.inputPassword m.shareState password }

        EndEditPassword ->
            Return.andThen <|
                \m ->
                    case ShareState.getToken m.shareState of
                        Just token ->
                            switchPage Page.Main m
                                |> Action.loadWithPasswordShareItem LoadWithPassword { password = ShareState.getPassword m.shareState, session = m.session, token = token }
                                |> Return.andThen startProgress

                        Nothing ->
                            Return.singleton m

        LoadWithPassword (Ok diagram) ->
            Return.andThen (\m -> Return.singleton { m | shareState = ShareState.authenticated m.shareState })
                >> Return.andThen (loadDiagram diagram)

        LoadWithPassword (Err e) ->
            Return.andThen (\m -> Return.singleton { m | shareState = ShareState.authenticatedError e })
                >> Return.andThen stopProgress

        MoveTo route ->
            Return.andThen unchanged
                >> Return.andThen closeDialog
                >> Return.andThen (moveTo route)

        CloseDialog ->
            Return.andThen closeDialog

        GotGithubAccessToken { cmd, accessToken } ->
            Return.andThen
                (\m ->
                    Return.singleton { m | session = Session.updateAccessToken m.session (accessToken |> Maybe.withDefault "") }
                        |> (if cmd == "save" then
                                Return.command (Task.perform identity (Task.succeed Save))

                            else
                                Action.loadItem Load { id = DiagramId.fromString cmd, session = m.session }
                           )
                )

        ChangeNetworkState isOnline ->
            Return.andThen <| \m -> Return.singleton { m | browserStatus = m.browserStatus |> Model.ofIsOnline.set isOnline }

        ShowEditor window ->
            Return.andThen <| \m -> Return.singleton { m | window = window }

        NotifyNewVersionAvailable msg ->
            Return.andThen
                (\m ->
                    Return.singleton
                        { m
                            | snackbar =
                                SnackbarModel.Show
                                    { message = msg
                                    , text = "RELOAD"
                                    , action = Reload
                                    }
                        }
                )
                >> Return.command (Utils.delay 30000 CloseSnackbar)

        Reload ->
            Return.command Nav.reload

        CloseSnackbar ->
            Return.andThen <| \m -> Return.singleton { m | snackbar = SnackbarModel.Hide }

        OpenLocalFile ->
            Return.command <| Ports.openLocalFile ()

        OpenedLocalFile ( title, text ) ->
            Return.andThen <| loadDiagram <| DiagramItem.localFile title text

        SaveLocalFile ->
            Return.andThen <|
                \m ->
                    Return.singleton m |> Action.saveLocalFile (DiagramItem.ofText.set (Text.saved m.diagramModel.text) m.currentDiagram)

        SavedLocalFile title ->
            Return.andThen <| \m -> loadDiagram (DiagramItem.localFile title <| Text.toString m.diagramModel.text) m


updateDiagramList : DiagramList.Msg -> Return.ReturnF Msg Model
updateDiagramList msg =
    case msg of
        DiagramList.Select diagram ->
            (case ( diagram.isRemote, diagram.isPublic ) of
                ( True, True ) ->
                    Return.andThen
                        (pushUrl
                            (Route.toString <|
                                ViewPublic diagram.diagram (DiagramItem.getId diagram)
                            )
                        )

                ( True, False ) ->
                    Return.andThen
                        (pushUrl
                            (Route.toString <|
                                EditFile diagram.diagram (DiagramItem.getId diagram)
                            )
                        )

                _ ->
                    Return.andThen
                        (pushUrl
                            (Route.toString <|
                                EditLocalFile diagram.diagram (DiagramItem.getId diagram)
                            )
                        )
            )
                >> Return.andThen startProgress
                >> Action.closeLocalFile

        DiagramList.Removed (Err _) ->
            Return.andThen <| showErrorMessage Message.messagEerrorOccurred

        DiagramList.GotDiagrams (Err _) ->
            Return.andThen <| showErrorMessage Message.messagEerrorOccurred

        DiagramList.ImportComplete json ->
            case DiagramItem.stringToList json of
                Ok _ ->
                    Return.andThen (showInfoMessage Message.messageImportCompleted)

                Err _ ->
                    Return.andThen <| showErrorMessage Message.messagEerrorOccurred

        _ ->
            Return.andThen stopProgress


updateSettings : Settings.Msg -> DiagramType -> Return.ReturnF Msg Model
updateSettings msg diagramType =
    case msg of
        Settings.UpdateSettings _ _ ->
            Return.andThen
                (\m ->
                    Return.singleton m
                        |> Action.saveSettings SaveSettings
                            { diagramType = diagramType
                            , session = m.session
                            , settings = m.settingsModel.settings
                            }
                        |> Return.andThen (setDiagramSettingsCache m.settingsModel.settings.storyMap)
                )

        _ ->
            Return.zero


updateShare : Model -> Share.Msg -> Return.ReturnF Msg Model
updateShare m msg =
    (case msg of
        Share.Shared (Err e) ->
            Return.andThen <| showErrorMessage e

        Share.Close ->
            Action.historyBack m.key

        Share.LoadShareCondition (Err e) ->
            Return.andThen <| showErrorMessage e

        _ ->
            Return.zero
    )
        >> Return.andThen stopProgress


view : Model -> Html Msg
view model =
    main_
        [ css [ position relative, Style.widthScreen ]
        , E.onClick CloseMenu
        ]
        [ GlobalStyle.style
        , if Window.isFullscreen model.window then
            Empty.view

          else
            Lazy.lazy Header.view
                { session = model.session
                , page = model.page
                , currentDiagram = model.currentDiagram
                , menu = model.openMenu
                , currentText = model.diagramModel.text
                , lang = model.lang
                , route = toRoute model.url
                , prevRoute = model.prevRoute
                , isOnline = model.browserStatus.isOnline
                }
        , Lazy.lazy Notification.view model.notification
        , Lazy.lazy Snackbar.view model.snackbar
        , Lazy.lazy showProgress model.progress
        , div
            [ css
                [ displayFlex
                , overflow hidden
                , position relative
                , Style.widthFull
                , if Window.isFullscreen model.window then
                    Css.batch [ Style.heightScreen ]

                  else
                    Css.batch [ Style.hContent ]
                ]
            ]
            [ if Route.isViewFile (toRoute model.url) || Window.isFullscreen model.window then
                Empty.view

              else
                Lazy.lazy Menu.view
                    { page = model.page
                    , route = toRoute model.url
                    , lang = model.lang
                    , text = model.diagramModel.text
                    , width = Size.getWidth model.diagramModel.size
                    , openMenu = model.openMenu
                    , settings = model.settingsModel.settings
                    , diagramType = model.currentDiagram.diagram
                    }
            , case model.page of
                Page.New ->
                    New.view

                Page.Help ->
                    Help.view

                Page.List ->
                    Lazy.lazy DiagramList.view model.diagramListModel |> Html.map UpdateDiagramList

                Page.Settings ->
                    Lazy.lazy Settings.view model.settingsModel |> Html.map UpdateSettings

                Page.Embed ->
                    Embed.view model

                Page.NotFound ->
                    NotFound.view

                _ ->
                    case toRoute model.url of
                        ViewFile _ id_ ->
                            case ShareToken.unwrap id_ |> Maybe.andThen Jwt.fromString of
                                Just jwt ->
                                    if jwt.checkEmail && Session.isGuest model.session then
                                        div
                                            [ css
                                                [ Style.flexCenter
                                                , TextStyle.xl
                                                , FontStyle.fontSemiBold
                                                , Style.widthScreen
                                                , ColorStyle.textColor
                                                , Style.mSm
                                                , height <| calc (vh 100) minus (px 40)
                                                ]
                                            ]
                                            [ img
                                                [ Asset.src Asset.logo
                                                , css [ width <| px 32 ]
                                                , alt "NOT FOUND"
                                                ]
                                                []
                                            , div [ css [ Style.mSm ] ] [ text "Sign in required" ]
                                            ]

                                    else
                                        div [ css [ Style.full, backgroundColor <| hex model.settingsModel.settings.storyMap.backgroundColor ] ]
                                            [ Lazy.lazy Diagram.view model.diagramModel
                                                |> Html.map UpdateDiagram
                                            ]

                                Nothing ->
                                    NotFound.view

                        _ ->
                            let
                                mainWindow : Html Msg -> Html Msg
                                mainWindow =
                                    if Size.getWidth model.diagramModel.size > 0 && Utils.isPhone (Size.getWidth model.diagramModel.size) then
                                        Lazy.lazy5 SwitchWindow.view
                                            SwitchWindow
                                            model.diagramModel.settings.backgroundColor
                                            model.window
                                            (div
                                                [ css
                                                    [ Breakpoint.style
                                                        [ Style.hMain
                                                        , Style.widthFull
                                                        , ColorStyle.bgMain
                                                        ]
                                                        [ Breakpoint.large [ Style.heightFull ] ]
                                                    ]
                                                ]
                                                [ editor model
                                                ]
                                            )

                                    else
                                        Lazy.lazy3 SplitWindow.view
                                            { background = model.diagramModel.settings.backgroundColor
                                            , window = model.window
                                            , onToggleEditor = ShowEditor
                                            , onResize = HandleStartWindowResize
                                            }
                                            (div
                                                [ css
                                                    [ Breakpoint.style
                                                        [ Style.hMain
                                                        , Style.widthFull
                                                        , ColorStyle.bgMain
                                                        ]
                                                        [ Breakpoint.large [ Style.heightFull ] ]
                                                    ]
                                                ]
                                                [ editor model
                                                ]
                                            )
                            in
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
                        if jwt.checkPassword && not (ShareState.isAuthenticated model.shareState) then
                            Lazy.lazy InputDialog.view
                                { title = "Protedted diagram"
                                , errorMessage = Maybe.map RequestError.toMessage (ShareState.getError model.shareState)
                                , value = ShareState.getPassword model.shareState |> Maybe.withDefault ""
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



-- Subscriptions


windowState : Window -> Bool -> Size -> Window
windowState window isFullscreen size =
    window
        |> (if isFullscreen then
                Window.fullscreen

            else if Utils.isPhone (Size.getWidth size) then
                Window.showEditor

            else
                Window.showEditorAndPreview
           )
