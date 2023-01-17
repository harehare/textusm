module Main exposing (Flags, main)

import Action
import Api.RequestError as RequestError
import Asset
import Attributes
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
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes as Attr
import Html.Styled.Events as E
import Html.Styled.Lazy as Lazy
import Json.Decode as D
import Message exposing (Message)
import Models.Diagram as DiagramModel
import Models.Diagram.Id as DiagramId
import Models.Diagram.Item as DiagramItem exposing (DiagramItem)
import Models.Diagram.Location as DiagramLocation exposing (Location)
import Models.Diagram.Scale as Scale
import Models.Diagram.Settings as DiagramSettings
import Models.Diagram.Type as DiagramType exposing (DiagramType(..))
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
import Models.Theme as Theme
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


type alias Flags =
    { lang : String
    , settings : D.Value
    , isOnline : Bool
    , isDarkMode : Bool
    , canUseClipboardItem : Bool
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
            switchPage Page.Main
                >> redirectToLastEditedFile
                >> Action.changeRouteInit Init

        Route.New ->
            switchPage Page.New

        Route.Edit diagramType ->
            let
                diagram : DiagramItem
                diagram =
                    DiagramItem.new diagramType
            in
            setCurrentDiagram diagram
                >> startProgress
                >> Return.andThen (\m -> Return.singleton m |> Action.loadSettings LoadSettings { cache = m.settingsCache, diagramType = m.currentDiagram.diagram, session = m.session })
                >> loadDiagram diagram
                >> switchPage Page.Main
                >> Action.changeRouteInit Init
                >> Action.closeLocalFile

        Route.EditFile _ id_ ->
            switchPage Page.Main
                >> Return.andThen
                    (\m ->
                        Return.singleton m
                            |> (if Session.isSignedIn m.session && m.browserStatus.isOnline then
                                    Action.updateIdToken
                                        >> startProgress
                                        >> Action.loadItem Load { id = id_, session = m.session }

                                else
                                    Action.loadLocalDiagram id_ >> Action.changeRouteInit Init
                               )
                            >> Action.loadSettings LoadSettings { cache = m.settingsCache, diagramType = m.currentDiagram.diagram, session = m.session }
                    )

        Route.EditLocalFile _ id_ ->
            switchPage Page.Main
                >> Action.loadLocalDiagram id_
                >> Action.changeRouteInit Init

        Route.ViewPublic _ id_ ->
            Action.updateIdToken
                >> switchPage Page.Main
                >> Return.andThen (\m -> Return.singleton m |> Action.loadPublicItem Load { id = id_, session = m.session })

        Route.DiagramList ->
            initListPage
                >> switchPage Page.List
                >> startProgress

        Route.Settings diagramType ->
            initSettingsPage diagramType
                >> switchPage Page.Settings

        Route.Help ->
            switchPage Page.Help

        Route.Share ->
            Return.andThen
                (\m ->
                    Return.singleton m
                        |> (if Session.isSignedIn m.session && m.currentDiagram.isRemote then
                                initShareDiagram m.currentDiagram
                                    >> startProgress

                            else
                                moveTo Route.Home
                           )
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
                                    |> DiagramModel.ofScale.set (Scale.fromFloat 1.0)
                                    |> DiagramModel.ofSize.set
                                        ( Maybe.withDefault (Size.getWidth m.diagramModel.size) width
                                        , Maybe.withDefault (Size.getHeight m.diagramModel.size) height
                                        )
                            , window = m.window |> Window.fullscreen
                        }
                )
                >> setTitle title
                >> Return.andThen (\m -> Return.singleton m |> Action.loadShareItem Load { session = m.session, token = id_ })
                >> switchPage Page.Embed
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
                            >> switchPage Page.Main
                            >> Action.changeRouteInit Init

                    else
                        Return.andThen
                            (\m ->
                                Return.singleton
                                    { m | shareState = ShareState.authenticateNoPassword id_ }
                                    |> Action.loadShareItem Load { session = m.session, token = id_ }
                            )
                            >> switchPage Page.Main
                            >> startProgress
                            >> Action.changeRouteInit Init

                Nothing ->
                    switchPage Page.NotFound

        Route.NotFound ->
            switchPage Page.NotFound


editor : Model -> Html Msg
editor model =
    let
        editorSettings : Settings.EditorSettings
        editorSettings =
            defaultEditorSettings model.settingsModel.settings.editor
    in
    Html.div [ Attr.id "editor", Attr.css [ Style.full, Style.paddingTopSm ] ]
        [ Html.node "monaco-editor"
            [ Attr.attribute "value" <| Text.toString model.diagramModel.text
            , Attr.attribute "fontSize" <| String.fromInt <| .fontSize <| defaultEditorSettings model.settingsModel.settings.editor
            , Attr.attribute "wordWrap" <|
                if editorSettings.wordWrap then
                    "true"

                else
                    "false"
            , Attr.attribute "showLineNumber" <|
                if editorSettings.showLineNumber then
                    "true"

                else
                    "false"
            , Attr.attribute "changed" <|
                if Text.isChanged model.diagramModel.text then
                    "true"

                else
                    "false"
            , Attr.attribute "diagramType" <| DiagramType.toTypeString model.currentDiagram.diagram
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
                |> Result.withDefault (defaultSettings (Theme.System flags.isDarkMode))

        lang : Message.Lang
        lang =
            Message.langFromString flags.lang

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
                , canUseClipboardItem = flags.canUseClipboardItem
                , canUseNativeFileSystem = flags.canUseNativeFileSystem
                }
            , confirmDialog = Dialog.Hide
            , snackbar = SnackbarModel.Hide
            , notification = Notification.Hide
            , settingsCache = SettingsCache.new
            , theme = Maybe.withDefault (Theme.System flags.isDarkMode) initSettings.theme
            }

        ( settingsModel, _ ) =
            Settings.init
                { canUseNativeFileSystem = flags.canUseNativeFileSystem
                , diagramType = currentDiagram.diagram
                , session = Session.guest
                , settings = initSettings
                , lang = lang
                , usableFontList = Just []
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


setCurrentDiagram : DiagramItem -> Return.ReturnF Msg Model
setCurrentDiagram currentDiagram =
    Return.map <| \m -> { m | currentDiagram = currentDiagram }


moveTo : Route -> Return.ReturnF Msg Model
moveTo route =
    Return.andThen <| \m -> Return.singleton m |> Return.command (Route.moveTo m.key route)


needSaved : Return.ReturnF Msg Model
needSaved =
    Return.map <| \m -> { m | diagramModel = m.diagramModel |> DiagramModel.ofText.set (Text.change m.diagramModel.text) }


pushUrl : String -> Return.ReturnF Msg Model
pushUrl url =
    Return.andThen <| \m -> Return.singleton m |> Return.command (Nav.pushUrl m.key url)


redirectToLastEditedFile : Return.ReturnF Msg Model
redirectToLastEditedFile =
    Return.andThen <|
        \m ->
            Return.singleton m
                |> (case ( m.currentDiagram.id, m.currentDiagram.diagram ) of
                        ( Just id_, diagramType ) ->
                            moveTo (Route.EditFile diagramType id_)

                        _ ->
                            Return.zero
                   )


startProgress : Return.ReturnF Msg Model
startProgress =
    Return.map <| \m -> { m | progress = True }


stopProgress : Return.ReturnF Msg Model
stopProgress =
    Return.map <| \m -> { m | progress = False }


showSnackbar : { message : String, text : String, action : Msg } -> Return.ReturnF Msg Model
showSnackbar { message, text, action } =
    Return.map <| \m -> { m | snackbar = SnackbarModel.Show { message = message, text = text, action = action } }


hideSnackbar : Return.ReturnF Msg Model
hideSnackbar =
    Return.map <| \m -> { m | snackbar = SnackbarModel.Hide }


switchPage : Page -> Return.ReturnF Msg Model
switchPage page =
    Return.map <| \m -> { m | page = page }


closeDialog : Return.ReturnF Msg Model
closeDialog =
    Return.map <| \m -> { m | confirmDialog = Dialog.Hide }


closeMenu : Return.ReturnF Msg Model
closeMenu =
    Return.map <| \m -> { m | openMenu = Nothing }


initListPage : Return.ReturnF Msg Model
initListPage =
    Return.andThen <|
        \m ->
            Return.singleton m.diagramListModel
                |> DiagramList.load { session = m.session, isOnline = m.browserStatus.isOnline }
                |> Return.mapBoth UpdateDiagramList (\m_ -> { m | diagramListModel = m_ })


updateListPage : DiagramList.Msg -> Return.ReturnF Msg Model
updateListPage msg =
    Return.andThen <|
        \m ->
            Return.singleton m.diagramListModel
                |> DiagramList.update msg
                |> Return.mapBoth UpdateDiagramList (\m_ -> { m | diagramListModel = m_ })


initSettingsPage : DiagramType -> Return.ReturnF Msg Model
initSettingsPage diagramType =
    Return.andThen <|
        \m ->
            Return.singleton m.settingsModel
                |> Settings.load { diagramType = diagramType, session = m.session }
                |> Return.mapBoth UpdateSettings (\m_ -> { m | settingsModel = m_ })


initShareDiagram : DiagramItem -> Return.ReturnF Msg Model
initShareDiagram diagramItem =
    Return.andThen <|
        \m ->
            Share.init
                { diagram = diagramItem.diagram
                , diagramId = diagramItem.id |> Maybe.withDefault (DiagramId.fromString "")
                , session = m.session
                , title = m.currentDiagram.title
                }
                |> Return.mapBoth UpdateShare (\m_ -> { m | shareModel = m_ })


updateShareDiagram : Share.Msg -> Return.ReturnF Msg Model
updateShareDiagram msg =
    Return.andThen <|
        \m ->
            Share.update msg m.shareModel
                |> Return.mapBoth UpdateShare (\m_ -> { m | shareModel = m_ })


closeNotification : Return.ReturnF Msg Model
closeNotification =
    Return.command (Utils.delay 3000 HandleCloseNotification)


showErrorMessage : Message -> Return.ReturnF Msg Model
showErrorMessage msg =
    Return.andThen <|
        \m ->
            Return.singleton m
                |> Return.command
                    (Notification.showErrorNotifcation (msg m.lang)
                        |> ShowNotification
                        |> Task.succeed
                        |> Task.perform identity
                    )
                |> closeNotification


showInfoMessage : Message -> Return.ReturnF Msg Model
showInfoMessage msg =
    Return.andThen <|
        \m ->
            Return.singleton m
                |> Return.command
                    (Notification.showInfoNotifcation (msg m.lang)
                        |> ShowNotification
                        |> Task.succeed
                        |> Task.perform identity
                    )
                |> closeNotification


showWarningMessage : Message -> Return.ReturnF Msg Model
showWarningMessage msg =
    Return.andThen <|
        \m ->
            Return.singleton m
                |> (Notification.showWarningNotifcation (msg m.lang)
                        |> ShowNotification
                        |> Task.succeed
                        |> Task.perform identity
                        |> Return.command
                   )
                >> closeNotification


loadDiagram : DiagramItem -> Return.ReturnF Msg Model
loadDiagram diagram =
    Return.andThen <|
        \m ->
            let
                diagramModel : DiagramModel.Model
                diagramModel =
                    m.diagramModel

                newDiagramModel : DiagramModel.Model
                newDiagramModel =
                    { diagramModel
                        | diagramType = diagram.diagram
                        , text = diagram.text
                    }
            in
            Return.singleton newDiagramModel
                |> Diagram.update (DiagramModel.ChangeText <| Text.toString diagram.text)
                >> Return.mapBoth UpdateDiagram
                    (\m_ ->
                        { m
                            | diagramModel = m_
                            , currentDiagram = diagram
                        }
                    )
                >> stopProgress


setDiagramSettings : DiagramSettings.Settings -> Return.ReturnF Msg Model
setDiagramSettings settings =
    Return.map
        (\m ->
            let
                newSettings : Settings.Model
                newSettings =
                    m.settingsModel
            in
            { m
                | diagramModel = m.diagramModel |> DiagramModel.ofSettings.set settings
                , settingsModel = { newSettings | settings = m.settingsModel.settings |> Settings.storyMapOfSettings.set settings }
            }
        )
        >> setDiagramSettingsCache settings


setDiagramSettingsCache : DiagramSettings.Settings -> Return.ReturnF Msg Model
setDiagramSettingsCache settings =
    Return.map <| \m -> { m | settingsCache = SettingsCache.set m.settingsCache m.currentDiagram.diagram settings }


updateWindowState : Return.ReturnF Msg Model
updateWindowState =
    Return.map <|
        \m ->
            { m
                | window =
                    m.window
                        |> (if Utils.isPhone (Size.getWidth m.diagramModel.size) then
                                Window.showEditor

                            else if Window.isFullscreen m.window then
                                Window.fullscreen

                            else
                                Window.showEditorAndPreview
                           )
            }


unchanged : Return.ReturnF Msg Model
unchanged =
    Return.map <| \m -> { m | diagramModel = m.diagramModel |> DiagramModel.ofText.set (Text.saved m.diagramModel.text) }


setTitle : String -> Return.ReturnF Msg Model
setTitle title =
    Return.map <| \m -> { m | currentDiagram = DiagramItem.ofTitle.set (Title.fromString <| title) m.currentDiagram }


showConfirmDialog : String -> String -> Route -> Return.ReturnF Msg Model
showConfirmDialog title message route =
    Return.map <| \m -> { m | confirmDialog = Dialog.Show { title = title, message = message, ok = MoveTo route, cancel = CloseDialog } }


startEditTitle : Return.ReturnF Msg Model
startEditTitle =
    Task.succeed StartEditTitle
        |> Task.perform identity
        |> Return.command


openCurrentFile : DiagramItem -> Return.ReturnF Msg Model
openCurrentFile diagram =
    (case ( diagram.isRemote, diagram.isPublic ) of
        ( True, True ) ->
            pushUrl (Route.toString <| ViewPublic diagram.diagram (DiagramItem.getId diagram))

        ( True, False ) ->
            pushUrl (Route.toString <| EditFile diagram.diagram (DiagramItem.getId diagram))

        _ ->
            pushUrl (Route.toString <| EditLocalFile diagram.diagram (DiagramItem.getId diagram))
    )
        >> Action.closeLocalFile



-- Update


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        ([ Ports.changeText (\text -> UpdateDiagram (DiagramModel.ChangeText text))
         , Ports.selectItemFromLineNo (\{ lineNo, text } -> UpdateDiagram (DiagramModel.SelectFromLineNo lineNo text))
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
                    Return.singleton m.diagramModel
                        |> Diagram.update (DiagramModel.Init m.diagramModel.settings window (Text.toString m.diagramModel.text))
                        |> Return.map
                            (\m_ ->
                                case toRoute m.url of
                                    Route.Embed _ _ _ (Just w) (Just h) ->
                                        let
                                            scale : Float
                                            scale =
                                                toFloat w
                                                    / toFloat (Size.getWidth m_.svg.size)
                                        in
                                        { m_ | size = ( w, h ), svg = { size = ( w, h ), scale = Scale.fromFloat scale } }

                                    _ ->
                                        m_
                            )
                        |> Return.mapBoth UpdateDiagram (\m_ -> { m | diagramModel = m_ })
                        |> Action.loadText Load m.currentDiagram
                        |> updateWindowState
                )
                >> stopProgress

        UpdateDiagram subMsg ->
            Return.andThen
                (\m ->
                    Return.singleton m.diagramModel
                        |> Diagram.update subMsg
                        |> Return.mapBoth UpdateDiagram (\m_ -> { m | diagramModel = m_ })
                        |> (case subMsg of
                                DiagramModel.ToggleFullscreen ->
                                    Return.andThen
                                        (\m_ ->
                                            Return.singleton { m_ | window = windowState m_.window m_.diagramModel.isFullscreen m_.diagramModel.size }
                                                |> Action.toggleFullscreen m_.window
                                        )

                                DiagramModel.Resize _ _ ->
                                    updateWindowState

                                _ ->
                                    Return.zero
                           )
                )

        UpdateDiagramList subMsg ->
            updateListPage subMsg >> Return.andThen (\m -> Return.singleton m |> processDiagramListMsg subMsg)

        UpdateShare subMsg ->
            updateShareDiagram subMsg >> processShareMsg subMsg

        UpdateSettings msg ->
            Return.andThen
                (\m ->
                    Return.singleton m.settingsModel
                        |> Settings.update msg
                        |> Return.mapBoth UpdateSettings
                            (\model_ ->
                                { m
                                    | diagramModel = m.diagramModel |> DiagramModel.ofSettings.set model_.settings.storyMap
                                    , page = Page.Settings
                                    , settingsModel = model_
                                }
                            )
                        |> updateSettings msg m.diagramModel.diagramType
                )

        OpenMenu menu ->
            Return.map <| \m -> { m | openMenu = Just menu }

        CloseMenu ->
            closeMenu

        MoveStop ->
            Return.map <| \m -> { m | window = Window.resized m.window }

        Copy ->
            Return.andThen (\m -> Return.singleton m |> pushUrl (Route.toString <| Edit m.currentDiagram.diagram))
                >> startProgress
                >> Action.closeLocalFile
                >> Return.andThen
                    (\m ->
                        Return.singleton m
                            |> (DiagramItem.copy m.currentDiagram
                                    |> Copied
                                    |> Utils.delay 100
                                    |> Return.command
                               )
                    )

        Copied diagram ->
            loadDiagram diagram

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
                        |> Maybe.map (Return.return m)
                        |> Maybe.withDefault (Return.singleton m)
                )

        DownloadCompleted ( x, y ) ->
            Return.map (\m -> { m | diagramModel = m.diagramModel |> DiagramModel.ofPosition.set ( x, y ) })

        StartDownload info ->
            Return.andThen
                (\m ->
                    Return.singleton m
                        |> Return.command (Download.string (Title.toString m.currentDiagram.title ++ info.extension) info.mimeType info.content)
                )
                >> closeMenu

        Save ->
            Return.andThen
                (\m ->
                    Return.singleton m
                        |> (if Title.isUntitled m.currentDiagram.title then
                                startEditTitle

                            else
                                let
                                    location : Maybe Location
                                    location =
                                        m.currentDiagram.id |> Maybe.map (\_ -> m.currentDiagram.location) |> Maybe.withDefault m.settingsModel.settings.location
                                in
                                case ( location, Session.isGithubUser m.session, Session.getAccessToken m.session ) of
                                    ( Just DiagramLocation.Gist, True, Nothing ) ->
                                        Return.command <| Ports.getGithubAccessToken "save"

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
                                        Return.map
                                            (\m_ ->
                                                { m_
                                                    | diagramModel = newDiagramModel
                                                    , diagramListModel = m_.diagramListModel |> DiagramList.modelOfDiagramList.set DiagramList.notAsked
                                                }
                                            )
                                            >> Action.saveDiagram
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
                )

        SaveToRemoteCompleted (Ok diagram) ->
            setCurrentDiagram diagram
                >> Return.andThen
                    (\m ->
                        Return.singleton m
                            |> (Maybe.withDefault (DiagramId.fromString "") diagram.id
                                    |> Route.EditFile diagram.diagram
                                    |> Route.replaceRoute m.key
                                    |> Return.command
                               )
                    )
                >> stopProgress
                >> showInfoMessage Message.messageSuccessfullySaved

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
                    Return.singleton m
                        |> setCurrentDiagram item
                        |> Action.saveToLocal item
                )
                >> stopProgress
                >> showWarningMessage Message.messageFailedSaved

        SaveToLocalCompleted diagramJson ->
            case D.decodeValue DiagramItem.decoder diagramJson of
                Ok item ->
                    Return.andThen
                        (\m ->
                            Return.singleton m
                                |> setCurrentDiagram item
                                |> (Maybe.withDefault (DiagramId.fromString "") item.id
                                        |> Route.EditLocalFile item.diagram
                                        |> Route.replaceRoute m.key
                                        |> Return.command
                                   )
                        )
                        >> showInfoMessage Message.messageSuccessfullySaved

                Err _ ->
                    Return.zero

        SaveToRemote diagramJson ->
            case D.decodeValue DiagramItem.decoder diagramJson of
                Ok diagram ->
                    Return.andThen
                        (\m ->
                            Return.singleton m
                                |> Action.saveToRemote SaveToRemoteCompleted { diagram = diagram, session = m.session, settings = m.settingsModel.settings }
                                |> startProgress
                        )

                Err _ ->
                    showWarningMessage Message.messageSuccessfullySaved >> stopProgress

        StartEditTitle ->
            Return.map (\m -> { m | currentDiagram = DiagramItem.ofTitle.set (Title.edit m.currentDiagram.title) m.currentDiagram })
                >> Action.setFocus NoOp "title"

        Progress visible ->
            Return.map <| \m -> { m | progress = visible }

        EndEditTitle ->
            Return.map (\m -> { m | currentDiagram = DiagramItem.ofTitle.set (Title.view m.currentDiagram.title) m.currentDiagram })
                >> Action.setFocusEditor

        EditTitle title ->
            Return.map (\m -> { m | currentDiagram = DiagramItem.ofTitle.set (Title.edit <| Title.fromString title) m.currentDiagram })
                >> needSaved

        SignIn provider ->
            Return.command (Ports.signIn <| LoginProdiver.toString provider)
                >> startProgress

        SignOut ->
            Return.andThen
                (\m ->
                    Return.singleton { m | session = Session.guest }
                        |> Action.revokeGistToken CallApi m.session
                        |> Return.command (Ports.signOut ())
                )
                >> setCurrentDiagram DiagramItem.empty

        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    Return.andThen <|
                        \m ->
                            Return.singleton m
                                |> (if Text.isChanged m.diagramModel.text && not (Dialog.display m.confirmDialog) then
                                        showConfirmDialog "Confirmation" "Your data has been changed. do you wish to continue?" (toRoute url)

                                    else
                                        case toRoute m.url of
                                            Route.Settings diagramType ->
                                                pushUrl (Url.toString url)
                                                    >> Action.saveSettings SaveSettings { session = m.session, diagramType = diagramType, settings = m.settingsModel.settings }
                                                    >> setDiagramSettingsCache m.settingsModel.settings.storyMap

                                            _ ->
                                                pushUrl (Url.toString url)
                                   )

                Browser.External href ->
                    Return.command <| Nav.load href

        UrlChanged url ->
            Return.map (\m -> { m | url = url, prevRoute = Just <| toRoute m.url }) >> changeRouteTo (toRoute url)

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
                                    , storyMap =
                                        DiagramSettings.ofScale.set
                                            (m.diagramModel.svg.scale
                                                |> Scale.toFloat
                                                |> Just
                                            )
                                            newStoryMap.storyMap
                                    , text = Just (Text.toString m.diagramModel.text)
                                    , title = Just <| Title.toString m.currentDiagram.title
                                    , editor = m.settingsModel.settings.editor
                                    , diagram = Just m.currentDiagram
                                    , location = m.settingsModel.settings.location
                                    , theme = m.settingsModel.settings.theme
                                    }

                                ( newSettingsModel, _ ) =
                                    Settings.init
                                        { canUseNativeFileSystem = m.browserStatus.canUseNativeFileSystem
                                        , diagramType = m.currentDiagram.diagram
                                        , session = m.session
                                        , settings = newSettings
                                        , lang = m.lang
                                        , usableFontList =
                                            if Settings.isFetchedUsableFont m.settingsModel then
                                                Just m.settingsModel.usableFontList

                                            else
                                                Nothing
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
            Return.map <| \m -> { m | window = Window.startResizing m.window x }

        HandleWindowResize x ->
            Return.map <| \m -> { m | window = Window.resizing m.window x }

        HandleAutoCloseNotification notification ->
            Return.map (\m -> { m | notification = notification })
                >> closeNotification

        HandleCloseNotification ->
            Return.map <| \m -> { m | notification = Notification.Hide }

        HandleAuthStateChanged (Just value) ->
            case D.decodeValue Session.decoder value of
                Ok user ->
                    Return.map (\m -> { m | session = Session.signIn user })
                        >> Return.andThen
                            (\m ->
                                Return.singleton m
                                    |> (case toRoute m.url of
                                            Route.EditFile type_ id_ ->
                                                if DiagramItem.getId m.currentDiagram /= id_ then
                                                    pushUrl (Route.toString <| Route.EditFile type_ id_)

                                                else
                                                    Return.zero

                                            Route.DiagramList ->
                                                pushUrl (Route.toString <| Route.Home)

                                            Route.ViewFile _ id_ ->
                                                case ShareToken.unwrap id_ |> Maybe.andThen Jwt.fromString of
                                                    Just jwt ->
                                                        if jwt.checkPassword then
                                                            switchPage Page.Main
                                                                >> Action.changeRouteInit Init

                                                        else
                                                            switchPage Page.Main
                                                                >> Action.loadShareItem Load { session = m.session, token = id_ }
                                                                >> startProgress
                                                                >> Action.changeRouteInit Init

                                                    Nothing ->
                                                        switchPage Page.NotFound

                                            _ ->
                                                Return.zero
                                       )
                            )
                        >> stopProgress

                Err _ ->
                    Return.map (\m -> { m | session = Session.guest })
                        >> stopProgress

        HandleAuthStateChanged Nothing ->
            Return.map (\m -> { m | session = Session.guest })
                >> moveTo Route.Home
                >> stopProgress

        ShowNotification notification ->
            Return.map <| \m -> { m | notification = notification }

        SwitchWindow w ->
            Return.map <| \m -> { m | window = Window.toggle w }

        Shortcuts cmd ->
            case cmd of
                Just Shortcuts.Open ->
                    Route.toString Route.DiagramList
                        |> Nav.load
                        |> Return.command

                Just Shortcuts.Save ->
                    Return.andThen <|
                        \m ->
                            Return.singleton m
                                |> (case ( m.settingsModel.settings.location, Text.isChanged m.diagramModel.text ) of
                                        ( Just DiagramLocation.LocalFileSystem, True ) ->
                                            Task.succeed SaveLocalFile
                                                |> Task.perform identity
                                                |> Return.command

                                        ( _, True ) ->
                                            Task.succeed Save
                                                |> Task.perform identity
                                                |> Return.command

                                        _ ->
                                            Return.zero
                                   )

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
                        |> stopProgress

        ChangePublicStatusCompleted (Ok d) ->
            setCurrentDiagram d
                >> stopProgress
                >> showInfoMessage Message.messagePublished

        ChangePublicStatusCompleted (Err _) ->
            showErrorMessage Message.messageFailedPublished
                >> stopProgress

        Load (Ok diagram) ->
            loadDiagram diagram

        Load (Err e) ->
            (case e of
                RequestError.NotFound ->
                    moveTo Route.NotFound

                _ ->
                    Return.zero
            )
                >> showErrorMessage (RequestError.toMessage e)
                >> stopProgress

        LoadSettings (Ok settings) ->
            setDiagramSettings settings >> stopProgress

        LoadSettings (Err _) ->
            Return.andThen (\m -> Return.singleton m |> setDiagramSettings (.storyMap (defaultSettings (Theme.System m.browserStatus.isDarkMode))))
                >> stopProgress

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
                                        , lang = m.lang
                                        , usableFontList =
                                            if Settings.isFetchedUsableFont m.settingsModel then
                                                Just m.settingsModel.usableFontList

                                            else
                                                Nothing
                                        }
                            in
                            Return.singleton { m | settingsModel = newSettingsModel, diagramModel = DiagramModel.ofSettings.set settings.storyMap m.diagramModel }
                        )

                Err _ ->
                    showWarningMessage Message.messageFailedLoadSettings

        SaveSettings (Ok _) ->
            stopProgress

        SaveSettings (Err _) ->
            showWarningMessage Message.messageFailedSaveSettings
                >> stopProgress

        CallApi (Ok ()) ->
            Return.zero

        CallApi (Err m) ->
            showErrorMessage m

        CloseFullscreen ->
            Return.andThen <|
                \m ->
                    Return.singleton m.diagramModel
                        |> Diagram.update DiagramModel.ToggleFullscreen
                        |> Return.mapBoth UpdateDiagram
                            (\m_ ->
                                { m
                                    | diagramModel = m_
                                    , window =
                                        m.window
                                            |> (if Utils.isPhone (Size.getWidth m.diagramModel.size) then
                                                    Window.showEditor

                                                else
                                                    Window.showEditorAndPreview
                                               )
                                }
                            )

        UpdateIdToken token ->
            Return.map <| \m -> { m | session = Session.updateIdToken m.session (IdToken.fromString token) }

        EditPassword password ->
            Return.map <| \m -> { m | shareState = ShareState.inputPassword m.shareState password }

        EndEditPassword ->
            Return.andThen <|
                \m ->
                    Return.singleton m
                        |> (case ShareState.getToken m.shareState of
                                Just token ->
                                    switchPage Page.Main
                                        >> Action.loadWithPasswordShareItem LoadWithPassword { password = ShareState.getPassword m.shareState, session = m.session, token = token }
                                        >> startProgress

                                Nothing ->
                                    Return.zero
                           )

        LoadWithPassword (Ok diagram) ->
            Return.map (\m -> { m | shareState = ShareState.authenticated m.shareState })
                >> loadDiagram diagram

        LoadWithPassword (Err e) ->
            Return.map (\m -> { m | shareState = ShareState.authenticatedError e })
                >> stopProgress

        MoveTo route ->
            unchanged
                >> closeDialog
                >> moveTo route

        CloseDialog ->
            closeDialog

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
            Return.map <| \m -> { m | browserStatus = m.browserStatus |> Model.ofIsOnline.set isOnline }

        ShowEditor window ->
            Return.map <| \m -> { m | window = window }

        NotifyNewVersionAvailable msg ->
            showSnackbar { message = msg, text = "RELOAD", action = Reload }
                >> Return.command (Utils.delay 30000 CloseSnackbar)

        Reload ->
            Return.command Nav.reload

        CloseSnackbar ->
            hideSnackbar

        OpenLocalFile ->
            Return.command <| Ports.openLocalFile ()

        OpenedLocalFile ( title, text ) ->
            loadDiagram <| DiagramItem.localFile title text

        SaveLocalFile ->
            Return.andThen <| \m -> Return.singleton m |> Action.saveLocalFile (DiagramItem.ofText.set (Text.saved m.diagramModel.text) m.currentDiagram)

        SavedLocalFile title ->
            Return.andThen <| \m -> Return.singleton m |> loadDiagram (DiagramItem.localFile title <| Text.toString m.diagramModel.text)

        ChangeDiagramType diagramType ->
            Return.andThen <|
                \m ->
                    Return.singleton { m | diagramModel = m.diagramModel |> DiagramModel.ofDiagramType.set diagramType }
                        |> loadDiagram (m.currentDiagram |> DiagramItem.ofDiagram.set diagramType)

        OpenCurrentFile ->
            Return.andThen <|
                \m ->
                    Return.singleton m
                        |> openCurrentFile m.currentDiagram


processDiagramListMsg : DiagramList.Msg -> Return.ReturnF Msg Model
processDiagramListMsg msg =
    case msg of
        DiagramList.Select diagram ->
            (case ( diagram.isRemote, diagram.isPublic ) of
                ( True, True ) ->
                    pushUrl (Route.toString <| ViewPublic diagram.diagram (DiagramItem.getId diagram))

                ( True, False ) ->
                    pushUrl (Route.toString <| EditFile diagram.diagram (DiagramItem.getId diagram))

                _ ->
                    pushUrl (Route.toString <| EditLocalFile diagram.diagram (DiagramItem.getId diagram))
            )
                >> startProgress
                >> Action.closeLocalFile

        DiagramList.Removed (Err _) ->
            showErrorMessage Message.messagEerrorOccurred

        DiagramList.GotDiagrams (Err _) ->
            showErrorMessage Message.messagEerrorOccurred

        DiagramList.ImportComplete json ->
            case DiagramItem.stringToList json of
                Ok _ ->
                    showInfoMessage Message.messageImportCompleted

                Err _ ->
                    showErrorMessage Message.messagEerrorOccurred

        _ ->
            stopProgress


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
                        |> setDiagramSettingsCache m.settingsModel.settings.storyMap
                )

        _ ->
            Return.zero


processShareMsg : Share.Msg -> Return.ReturnF Msg Model
processShareMsg msg =
    Return.andThen <|
        \m ->
            Return.singleton m
                |> (case msg of
                        Share.Shared (Err e) ->
                            showErrorMessage e

                        Share.Close ->
                            Action.historyBack m.key

                        Share.LoadShareCondition (Err e) ->
                            showErrorMessage e

                        _ ->
                            Return.zero
                   )
                |> stopProgress


view : Model -> Html Msg
view model =
    Html.main_
        [ Attr.css [ position relative, Style.widthScreen ]
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
        , Html.div
            [ Attr.css
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
                    , currentDiagram = model.currentDiagram
                    , browserStatus = model.browserStatus
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
                                        Html.div
                                            [ Attr.css
                                                [ Style.flexCenter
                                                , TextStyle.xl
                                                , FontStyle.fontSemiBold
                                                , Style.widthScreen
                                                , ColorStyle.textColor
                                                , Style.mSm
                                                , height <| calc (vh 100) minus (px 40)
                                                ]
                                            ]
                                            [ Html.img
                                                [ Asset.src Asset.logo
                                                , Attr.css [ width <| px 32 ]
                                                , Attr.alt "NOT FOUND"
                                                ]
                                                []
                                            , Html.div [ Attr.css [ Style.mSm ] ] [ Html.text "Sign in required" ]
                                            ]

                                    else
                                        Html.div [ Attr.css [ Style.full, backgroundColor <| hex model.settingsModel.settings.storyMap.backgroundColor ] ]
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
                                            (Html.div
                                                [ Attr.css
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
                                            (Html.div
                                                [ Attr.css
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
        , Footer.view { diagramType = model.currentDiagram.diagram, onChangeDiagramType = ChangeDiagramType }
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
