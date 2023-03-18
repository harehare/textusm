module Main exposing (Flags, main)

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
import Effect
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
import Models.LoginProvider as LoginProvider
import Models.Model as M exposing (Model, Msg)
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
        )
import String
import Style.Breakpoint as Breakpoint
import Style.Color as ColorStyle
import Style.Font as FontStyle
import Style.Global as GlobalStyle
import Style.Style as Style
import Style.Text as TextStyle
import Task
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
        , onUrlChange = M.UrlChanged
        , onUrlRequest = M.LinkClicked
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
                >> Effect.changeRouteInit M.Init

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
                >> Return.andThen (\m -> Return.singleton m |> Effect.loadSettings M.LoadSettings { cache = m.settingsCache, diagramType = m.currentDiagram.diagram, session = m.session })
                >> loadDiagram diagram
                >> switchPage Page.Main
                >> Effect.changeRouteInit M.Init
                >> Effect.closeLocalFile

        Route.EditFile _ id_ ->
            switchPage Page.Main
                >> Return.andThen
                    (\m ->
                        Return.singleton m
                            |> (if Session.isSignedIn m.session && m.browserStatus.isOnline then
                                    Effect.updateIdToken
                                        >> startProgress
                                        >> Effect.loadItem M.Load { id = id_, session = m.session }

                                else
                                    Effect.loadLocalDiagram id_ >> Effect.changeRouteInit M.Init
                               )
                            >> Effect.loadSettings M.LoadSettings { cache = m.settingsCache, diagramType = m.currentDiagram.diagram, session = m.session }
                    )

        Route.EditLocalFile _ id_ ->
            switchPage Page.Main
                >> Effect.loadLocalDiagram id_
                >> Effect.changeRouteInit M.Init

        Route.ViewPublic _ id_ ->
            Effect.updateIdToken
                >> switchPage Page.Main
                >> Return.andThen (\m -> Return.singleton m |> Effect.loadPublicItem M.Load { id = id_, session = m.session })

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
                        |> (case ( m.session, m.currentDiagram.location ) of
                                ( Session.SignedIn _, Just DiagramLocation.Remote ) ->
                                    initShareDiagram m.currentDiagram >> startProgress

                                _ ->
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
                                    |> DiagramModel.ofWindowSize.set
                                        ( Maybe.withDefault (Size.getWidth m.diagramModel.windowSize) width
                                        , Maybe.withDefault (Size.getHeight m.diagramModel.windowSize) height
                                        )
                            , window = m.window |> Window.fullscreen
                        }
                )
                >> setTitle title
                >> Return.andThen (\m -> Return.singleton m |> Effect.loadShareItem M.Load { session = m.session, token = id_ })
                >> switchPage Page.Embed
                >> Effect.changeRouteInit M.Init

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
                            >> Effect.changeRouteInit M.Init

                    else
                        Return.andThen
                            (\m ->
                                Return.singleton
                                    { m | shareState = ShareState.authenticateNoPassword id_ }
                                    |> Effect.loadShareItem M.Load { session = m.session, token = id_ }
                            )
                            >> switchPage Page.Main
                            >> startProgress
                            >> Effect.changeRouteInit M.Init

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
                |> Return.mapBoth M.UpdateDiagramList (\m_ -> { m | diagramListModel = m_ })


updateListPage : DiagramList.Msg -> Return.ReturnF Msg Model
updateListPage msg =
    Return.andThen <|
        \m ->
            Return.singleton m.diagramListModel
                |> DiagramList.update msg
                |> Return.mapBoth M.UpdateDiagramList (\m_ -> { m | diagramListModel = m_ })


initSettingsPage : DiagramType -> Return.ReturnF Msg Model
initSettingsPage diagramType =
    Return.andThen <|
        \m ->
            Return.singleton m.settingsModel
                |> Settings.load { diagramType = diagramType, session = m.session }
                |> Return.mapBoth M.UpdateSettings (\m_ -> { m | settingsModel = m_ })


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
                |> Return.mapBoth M.UpdateShare (\m_ -> { m | shareModel = m_ })


updateShareDiagram : Share.Msg -> Return.ReturnF Msg Model
updateShareDiagram msg =
    Return.andThen <|
        \m ->
            Share.update msg m.shareModel
                |> Return.mapBoth M.UpdateShare (\m_ -> { m | shareModel = m_ })


closeNotification : Return.ReturnF Msg Model
closeNotification =
    Return.command (Utils.delay 3000 M.HandleCloseNotification)


showErrorMessage : Message -> Return.ReturnF Msg Model
showErrorMessage msg =
    Return.andThen <|
        \m ->
            Return.singleton m
                |> Return.command
                    (Notification.showErrorNotifcation (msg m.lang)
                        |> M.ShowNotification
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
                        |> M.ShowNotification
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
                        |> M.ShowNotification
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
                >> Return.mapBoth M.UpdateDiagram
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
                        |> (if Utils.isPhone (Size.getWidth m.diagramModel.windowSize) then
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
    Return.map <| \m -> { m | confirmDialog = Dialog.Show { title = title, message = message, ok = M.MoveTo route, cancel = M.CloseDialog } }


openCurrentFile : DiagramItem -> Return.ReturnF Msg Model
openCurrentFile diagram =
    (case ( diagram.location, diagram.isPublic ) of
        ( Just DiagramLocation.Remote, True ) ->
            pushUrl (Route.toString <| ViewPublic diagram.diagram (DiagramItem.getId diagram))

        ( Just DiagramLocation.Remote, False ) ->
            pushUrl (Route.toString <| EditFile diagram.diagram (DiagramItem.getId diagram))

        _ ->
            pushUrl (Route.toString <| EditLocalFile diagram.diagram (DiagramItem.getId diagram))
    )
        >> Effect.closeLocalFile


save : Return.ReturnF Msg Model
save =
    (\m ->
        Return.singleton m
            |> (let
                    location : Location
                    location =
                        m.currentDiagram.location
                            |> Maybe.withDefault
                                (if
                                    m.currentDiagram
                                        |> DiagramItem.isRemoteDiagram m.session
                                 then
                                    m.settingsModel.settings.location
                                        |> Maybe.withDefault DiagramLocation.Remote

                                 else
                                    DiagramLocation.Local
                                )

                    newDiagramModel : DiagramModel.Model
                    newDiagramModel =
                        DiagramModel.updatedText m.diagramModel (Text.saved m.diagramModel.text)

                    diagram : DiagramItem
                    diagram =
                        m.currentDiagram
                            |> DiagramItem.ofText.set newDiagramModel.text
                            |> DiagramItem.ofThumbnail.set Nothing
                            |> DiagramItem.ofLocation.set (Just location)
                            |> DiagramItem.ofDiagram.set newDiagramModel.diagramType
                in
                Return.map
                    (\m_ ->
                        { m_
                            | diagramModel = newDiagramModel
                            , diagramListModel = m_.diagramListModel |> DiagramList.modelOfDiagramList.set DiagramList.notAsked
                        }
                    )
                    >> (case ( location, Session.loginProvider m.session ) of
                            ( DiagramLocation.Gist, Just (LoginProvider.Github Nothing) ) ->
                                Return.command <| Ports.getGithubAccessToken "save"

                            ( DiagramLocation.Gist, _ ) ->
                                Effect.saveDiagram diagram

                            ( DiagramLocation.Remote, _ ) ->
                                Effect.saveDiagram diagram

                            ( DiagramLocation.LocalFileSystem, _ ) ->
                                Return.zero

                            ( DiagramLocation.Local, _ ) ->
                                Return.zero
                       )
               )
    )
        |> Return.andThen



-- Update


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        ([ Ports.changeText (\text -> M.UpdateDiagram (DiagramModel.ChangeText text))
         , Ports.selectItemFromLineNo (\{ lineNo, text } -> M.UpdateDiagram (DiagramModel.SelectFromLineNo lineNo text))
         , Ports.loadSettingsFromLocalCompleted M.LoadSettingsFromLocal
         , Ports.startDownload M.StartDownload
         , Ports.gotLocalDiagramsJson (\json -> M.UpdateDiagramList (DiagramList.GotLocalDiagramsJson json))
         , Ports.reload (\_ -> M.UpdateDiagramList DiagramList.Reload)
         , onVisibilityChange M.HandleVisibilityChange
         , onResize (\width height -> M.UpdateDiagram (DiagramModel.Resize width height))
         , Ports.shortcuts (\cmd -> M.Shortcuts <| Shortcuts.fromString cmd)
         , Ports.onNotification (\n -> M.HandleAutoCloseNotification (Notification.showInfoNotifcation n))
         , Ports.sendErrorNotification (\n -> M.HandleAutoCloseNotification (Notification.showErrorNotifcation n))
         , Ports.onWarnNotification (\n -> M.HandleAutoCloseNotification (Notification.showWarningNotifcation n))
         , Ports.onAuthStateChanged M.HandleAuthStateChanged
         , Ports.saveToRemote M.SaveToRemote
         , Ports.removeRemoteDiagram (\diagram -> M.UpdateDiagramList <| DiagramList.RemoveRemote diagram)
         , Ports.downloadCompleted M.DownloadCompleted
         , Ports.progress M.Progress
         , Ports.saveToLocalCompleted M.SaveToLocalCompleted
         , Ports.gotLocalDiagramJson M.GotLocalDiagramJson
         , Ports.fullscreen <|
            \f ->
                if f then
                    M.NoOp

                else
                    M.CloseFullscreen
         , Ports.updateIdToken M.UpdateIdToken
         , Ports.gotGithubAccessToken M.GotGithubAccessToken
         , Ports.changeNetworkState M.ChangeNetworkState
         , Ports.notifyNewVersionAvailable M.NotifyNewVersionAvailable
         , Ports.openedLocalFile M.OpenedLocalFile
         , Ports.savedLocalFile M.SavedLocalFile
         ]
            ++ (if Window.isResizing model.window then
                    [ onMouseUp <| D.succeed M.MoveStop
                    , onMouseMove <| D.map M.HandleWindowResize (D.field "pageX" D.int)
                    ]

                else
                    [ Sub.none ]
               )
        )


update : Msg -> Return.ReturnF Msg Model
update message =
    case message of
        M.NoOp ->
            Return.zero

        M.Init window ->
            (\m ->
                Return.singleton m.diagramModel
                    |> Diagram.update (DiagramModel.Init m.diagramModel.settings window (Text.toString m.diagramModel.text))
                    |> Return.map
                        (\m_ ->
                            case toRoute m.url of
                                Route.Embed _ _ _ (Just w) (Just h) ->
                                    -- TODO:
                                    let
                                        scale : Float
                                        scale =
                                            toFloat w
                                                / toFloat (Size.getWidth m_.diagram.size)
                                    in
                                    { m_
                                        | windowSize = ( w, h )
                                        , diagram =
                                            { size = ( w, h )
                                            , scale = Scale.fromFloat scale
                                            , position = m_.diagram.position
                                            , isFullscreen = m_.diagram.isFullscreen
                                            }
                                    }

                                _ ->
                                    m_
                        )
                    |> Return.mapBoth M.UpdateDiagram (\m_ -> { m | diagramModel = m_ })
                    |> Effect.loadText M.Load m.currentDiagram
                    |> updateWindowState
            )
                >> stopProgress
                |> Return.andThen

        M.UpdateDiagram subMsg ->
            (\m ->
                Return.singleton m.diagramModel
                    |> Diagram.update subMsg
                    |> Return.mapBoth M.UpdateDiagram (\m_ -> { m | diagramModel = m_ })
                    |> (case subMsg of
                            DiagramModel.ToggleFullscreen ->
                                Return.andThen
                                    (\m_ ->
                                        Return.singleton { m_ | window = windowState m_.window m_.diagramModel.diagram.isFullscreen m_.diagramModel.windowSize }
                                            |> Effect.toggleFullscreen m_.window
                                    )

                            DiagramModel.Resize _ _ ->
                                updateWindowState

                            _ ->
                                Return.zero
                       )
            )
                |> Return.andThen

        M.UpdateDiagramList subMsg ->
            updateListPage subMsg >> Return.andThen (\m -> Return.singleton m |> processDiagramListMsg subMsg)

        M.UpdateShare subMsg ->
            updateShareDiagram subMsg >> processShareMsg subMsg

        M.UpdateSettings msg ->
            Return.andThen
                (\m ->
                    Return.singleton m.settingsModel
                        |> Settings.update msg
                        |> Return.mapBoth M.UpdateSettings
                            (\model_ ->
                                { m
                                    | diagramModel = m.diagramModel |> DiagramModel.ofSettings.set model_.settings.storyMap
                                    , page = Page.Settings
                                    , settingsModel = model_
                                }
                            )
                        |> updateSettings msg m.diagramModel.diagramType
                )

        M.OpenMenu menu ->
            Return.map <| \m -> { m | openMenu = Just menu }

        M.CloseMenu ->
            closeMenu

        M.MoveStop ->
            Return.map <| \m -> { m | window = Window.resized m.window }

        M.Copy ->
            Return.andThen (\m -> Return.singleton m |> pushUrl (Route.toString <| Edit m.currentDiagram.diagram))
                >> startProgress
                >> Effect.closeLocalFile
                >> Return.andThen
                    (\m ->
                        Return.singleton m
                            |> (DiagramItem.copy m.currentDiagram
                                    |> M.Copied
                                    |> Utils.delay 100
                                    |> Return.command
                               )
                    )

        M.Copied diagram ->
            loadDiagram diagram

        M.Download exportDiagram ->
            Return.andThen
                (\m ->
                    let
                        ( posX, posY ) =
                            m.diagramModel.diagram.position
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

        M.DownloadCompleted ( x, y ) ->
            Return.map (\m -> { m | diagramModel = m.diagramModel |> DiagramModel.ofPosition.set ( x, y ) })

        M.StartDownload info ->
            (\m ->
                Return.singleton m
                    |> Return.command (Download.string (Title.toString m.currentDiagram.title ++ info.extension) info.mimeType info.content)
            )
                >> closeMenu
                |> Return.andThen

        M.Save ->
            save

        M.SaveToRemoteCompleted (Ok diagram) ->
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

        M.SaveToRemoteCompleted (Err _) ->
            (\m ->
                let
                    item : DiagramItem
                    item =
                        m.currentDiagram
                            |> DiagramItem.ofText.set m.diagramModel.text
                            |> DiagramItem.ofThumbnail.set Nothing
                            |> DiagramItem.ofLocation.set (Just DiagramLocation.Local)
                            |> DiagramItem.ofDiagram.set m.diagramModel.diagramType
                in
                Return.singleton m
                    |> setCurrentDiagram item
                    |> Effect.saveToLocal item
            )
                >> stopProgress
                >> showWarningMessage Message.messageFailedSaved
                |> Return.andThen

        M.SaveToLocalCompleted diagramJson ->
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

        M.SaveToRemote diagramJson ->
            case D.decodeValue DiagramItem.decoder diagramJson of
                Ok diagram ->
                    Return.andThen
                        (\m ->
                            Return.singleton m
                                |> Effect.saveToRemote M.SaveToRemoteCompleted { diagram = diagram, session = m.session, settings = m.settingsModel.settings }
                                |> startProgress
                        )

                Err _ ->
                    showWarningMessage Message.messageSuccessfullySaved >> stopProgress

        M.StartEditTitle ->
            Return.map (\m -> { m | currentDiagram = DiagramItem.ofTitle.set (Title.edit m.currentDiagram.title) m.currentDiagram })
                >> Effect.setFocus M.NoOp "title"

        M.Progress visible ->
            Return.map <| \m -> { m | progress = visible }

        M.EndEditTitle ->
            Return.map (\m -> { m | currentDiagram = DiagramItem.ofTitle.set (Title.view m.currentDiagram.title) m.currentDiagram })
                >> Effect.setFocusEditor

        M.EditTitle title ->
            Return.map (\m -> { m | currentDiagram = DiagramItem.ofTitle.set (Title.edit <| Title.fromString title) m.currentDiagram })
                >> needSaved

        M.SignIn provider ->
            Return.command (Ports.signIn <| LoginProvider.toString provider)
                >> startProgress

        M.SignOut ->
            (\m ->
                Return.singleton { m | session = Session.guest }
                    |> Effect.revokeGistToken M.CallApi m.session
                    |> Return.command (Ports.signOut ())
            )
                >> setCurrentDiagram DiagramItem.empty
                |> Return.andThen

        M.LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    (\m ->
                        Return.singleton m
                            |> (if Text.isChanged m.diagramModel.text && not (Dialog.display m.confirmDialog) then
                                    showConfirmDialog "Confirmation" "Your data has been changed. do you wish to continue?" (toRoute url)

                                else
                                    case toRoute m.url of
                                        Route.Settings diagramType ->
                                            pushUrl (Url.toString url)
                                                >> Effect.saveDiagramSettings M.SaveDiagramSettings { session = m.session, diagramType = diagramType, settings = m.settingsModel.settings }
                                                >> setDiagramSettingsCache m.settingsModel.settings.storyMap

                                        _ ->
                                            pushUrl (Url.toString url)
                               )
                    )
                        |> Return.andThen

                Browser.External href ->
                    Return.command <| Nav.load href

        M.UrlChanged url ->
            Return.map (\m -> { m | url = url, prevRoute = Just <| toRoute m.url }) >> changeRouteTo (toRoute url)

        M.HandleVisibilityChange visible ->
            case visible of
                Hidden ->
                    (\m ->
                        let
                            newSettings : Settings
                            newSettings =
                                { position = Just m.window.position
                                , font = m.settingsModel.settings.font
                                , diagramId = Maybe.map DiagramId.toString m.currentDiagram.id
                                , storyMap =
                                    DiagramSettings.ofScale.set
                                        (m.diagramModel.diagram.scale
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
                            |> Effect.saveSettingsToLocal newSettings
                    )
                        |> Return.andThen

                _ ->
                    Return.zero

        M.HandleStartWindowResize x ->
            Return.map <| \m -> { m | window = Window.startResizing m.window x }

        M.HandleWindowResize x ->
            Return.map <| \m -> { m | window = Window.resizing m.window x }

        M.HandleAutoCloseNotification notification ->
            Return.map (\m -> { m | notification = notification })
                >> closeNotification

        M.HandleCloseNotification ->
            Return.map <| \m -> { m | notification = Notification.Hide }

        M.HandleAuthStateChanged (Just value) ->
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
                                                                >> Effect.changeRouteInit M.Init

                                                        else
                                                            switchPage Page.Main
                                                                >> Effect.loadShareItem M.Load { session = m.session, token = id_ }
                                                                >> startProgress
                                                                >> Effect.changeRouteInit M.Init

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

        M.HandleAuthStateChanged Nothing ->
            Return.map (\m -> { m | session = Session.guest })
                >> moveTo Route.Home
                >> stopProgress

        M.ShowNotification notification ->
            Return.map <| \m -> { m | notification = notification }

        M.SwitchWindow w ->
            Return.map <| \m -> { m | window = Window.toggle w }

        M.Shortcuts cmd ->
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
                                            Task.succeed M.SaveLocalFile
                                                |> Task.perform identity
                                                |> Return.command

                                        ( _, True ) ->
                                            Task.succeed M.Save
                                                |> Task.perform identity
                                                |> Return.command

                                        _ ->
                                            Return.zero
                                   )

                _ ->
                    Return.zero

        M.GotLocalDiagramJson json ->
            case D.decodeValue DiagramItem.decoder json of
                Ok item ->
                    Effect.loadText M.Load item

                Err _ ->
                    Return.zero

        M.ChangePublicStatus isPublic ->
            Return.andThen <|
                \m ->
                    Return.singleton m
                        |> Effect.updateIdToken
                        |> Effect.changePublicState M.ChangePublicStatusCompleted { isPublic = isPublic, item = m.currentDiagram, session = m.session }
                        |> stopProgress

        M.ChangePublicStatusCompleted (Ok d) ->
            setCurrentDiagram d
                >> stopProgress
                >> showInfoMessage Message.messagePublished

        M.ChangePublicStatusCompleted (Err _) ->
            showErrorMessage Message.messageFailedPublished
                >> stopProgress

        M.Load (Ok diagram) ->
            loadDiagram diagram

        M.Load (Err e) ->
            (case e of
                RequestError.NotFound ->
                    moveTo Route.NotFound

                _ ->
                    Return.zero
            )
                >> showErrorMessage (RequestError.toMessage e)
                >> stopProgress

        M.LoadSettings (Ok settings) ->
            setDiagramSettings settings >> stopProgress

        M.LoadSettings (Err _) ->
            Return.andThen (\m -> Return.singleton m |> setDiagramSettings (.storyMap (defaultSettings (Theme.System m.browserStatus.isDarkMode))))
                >> stopProgress

        M.LoadSettingsFromLocal settingsJson ->
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

        M.SaveDiagramSettings (Ok _) ->
            stopProgress

        M.SaveDiagramSettings (Err _) ->
            showWarningMessage Message.messageFailedSaveSettings
                >> stopProgress

        M.CallApi (Ok ()) ->
            Return.zero

        M.CallApi (Err m) ->
            showErrorMessage m

        M.CloseFullscreen ->
            Return.andThen <|
                \m ->
                    Return.singleton m.diagramModel
                        |> Diagram.update DiagramModel.ToggleFullscreen
                        |> Return.mapBoth M.UpdateDiagram
                            (\m_ ->
                                { m
                                    | diagramModel = m_
                                    , window =
                                        m.window
                                            |> (if Utils.isPhone (Size.getWidth m.diagramModel.windowSize) then
                                                    Window.showEditor

                                                else
                                                    Window.showEditorAndPreview
                                               )
                                }
                            )

        M.UpdateIdToken token ->
            Return.map <| \m -> { m | session = Session.updateIdToken m.session (IdToken.fromString token) }

        M.EditPassword password ->
            Return.map <| \m -> { m | shareState = ShareState.inputPassword m.shareState password }

        M.EndEditPassword ->
            Return.andThen <|
                \m ->
                    Return.singleton m
                        |> (case ShareState.getToken m.shareState of
                                Just token ->
                                    switchPage Page.Main
                                        >> Effect.loadWithPasswordShareItem M.LoadWithPassword { password = ShareState.getPassword m.shareState, session = m.session, token = token }
                                        >> startProgress

                                Nothing ->
                                    Return.zero
                           )

        M.LoadWithPassword (Ok diagram) ->
            Return.map (\m -> { m | shareState = ShareState.authenticated m.shareState })
                >> loadDiagram diagram

        M.LoadWithPassword (Err e) ->
            Return.map (\m -> { m | shareState = ShareState.authenticatedError e })
                >> stopProgress

        M.MoveTo route ->
            unchanged
                >> closeDialog
                >> moveTo route

        M.CloseDialog ->
            closeDialog

        M.GotGithubAccessToken { cmd, accessToken } ->
            Return.andThen
                (\m ->
                    Return.singleton { m | session = Session.updateAccessToken m.session (accessToken |> Maybe.withDefault "") }
                        |> (if cmd == "save" then
                                Return.command (Task.perform identity (Task.succeed M.Save))

                            else
                                Effect.loadItem M.Load { id = DiagramId.fromString cmd, session = m.session }
                           )
                )

        M.ChangeNetworkState isOnline ->
            Return.map <| \m -> { m | browserStatus = m.browserStatus |> M.ofIsOnline.set isOnline }

        M.ShowEditor window ->
            Return.map <| \m -> { m | window = window }

        M.NotifyNewVersionAvailable msg ->
            showSnackbar { message = msg, text = "RELOAD", action = M.Reload }
                >> Return.command (Utils.delay 30000 M.CloseSnackbar)

        M.Reload ->
            Return.command Nav.reload

        M.CloseSnackbar ->
            hideSnackbar

        M.OpenLocalFile ->
            Return.command <| Ports.openLocalFile ()

        M.OpenedLocalFile ( title, text ) ->
            loadDiagram <| DiagramItem.localFile title text

        M.SaveLocalFile ->
            Return.andThen <| \m -> Return.singleton m |> Effect.saveLocalFile (DiagramItem.ofText.set (Text.saved m.diagramModel.text) m.currentDiagram)

        M.SavedLocalFile title ->
            Return.andThen <| \m -> Return.singleton m |> loadDiagram (DiagramItem.localFile title <| Text.toString m.diagramModel.text)

        M.ChangeDiagramType diagramType ->
            Return.andThen <|
                \m ->
                    Return.singleton { m | diagramModel = m.diagramModel |> DiagramModel.ofDiagramType.set diagramType }
                        |> loadDiagram (m.currentDiagram |> DiagramItem.ofDiagram.set diagramType)

        M.OpenCurrentFile ->
            Return.andThen <|
                \m ->
                    Return.singleton m
                        |> openCurrentFile m.currentDiagram


processDiagramListMsg : DiagramList.Msg -> Return.ReturnF Msg Model
processDiagramListMsg msg =
    case msg of
        DiagramList.Select diagram ->
            (case ( diagram.location, diagram.isPublic ) of
                ( Just DiagramLocation.Remote, True ) ->
                    pushUrl (Route.toString <| ViewPublic diagram.diagram (DiagramItem.getId diagram))

                ( Just DiagramLocation.Remote, False ) ->
                    pushUrl (Route.toString <| EditFile diagram.diagram (DiagramItem.getId diagram))

                _ ->
                    pushUrl (Route.toString <| EditLocalFile diagram.diagram (DiagramItem.getId diagram))
            )
                >> startProgress
                >> Effect.closeLocalFile

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
                        |> Effect.saveDiagramSettings M.SaveDiagramSettings
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
                            Effect.historyBack m.key

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
        , E.onClick M.CloseMenu
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
                    , width = Size.getWidth model.diagramModel.windowSize
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
                    Lazy.lazy DiagramList.view model.diagramListModel |> Html.map M.UpdateDiagramList

                Page.Settings ->
                    Lazy.lazy Settings.view model.settingsModel |> Html.map M.UpdateSettings

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
                                                |> Html.map M.UpdateDiagram
                                            ]

                                Nothing ->
                                    NotFound.view

                        _ ->
                            let
                                mainWindow : Html Msg -> Html Msg
                                mainWindow =
                                    if Size.getWidth model.diagramModel.windowSize > 0 && Utils.isPhone (Size.getWidth model.diagramModel.windowSize) then
                                        Lazy.lazy5 SwitchWindow.view
                                            M.SwitchWindow
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
                                            , onToggleEditor = M.ShowEditor
                                            , onResize = M.HandleStartWindowResize
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
                                    |> Html.map M.UpdateDiagram
                                )
            ]
        , case toRoute model.url of
            Share ->
                Lazy.lazy Share.view model.shareModel |> Html.map M.UpdateShare

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
                                , onInput = M.EditPassword
                                , onEnter = M.EndEditPassword
                                }

                        else
                            Empty.view

                    Nothing ->
                        Empty.view

            _ ->
                Empty.view
        , Lazy.lazy showDialog model.confirmDialog
        , Footer.view { diagramType = model.currentDiagram.diagram, onChangeDiagramType = M.ChangeDiagramType }
        ]




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
