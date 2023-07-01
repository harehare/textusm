module Main exposing (Flags, main)

import Api.RequestError as RequestError
import Asset
import Attributes
import Bool.Extra as BoolEx
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
import Css exposing (backgroundColor, calc, displayFlex, height, hidden, minus, overflow, position, px, relative, vh, width)
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
import Models.Hotkey as Hotkey
import Models.IdToken as IdToken
import Models.Jwt as Jwt
import Models.LoginProvider as LoginProvider
import Models.Model as M exposing (Model, Msg)
import Models.Notification as Notification
import Models.Page as Page exposing (Page)
import Models.Session as Session
import Models.Settings as Settings
    exposing
        ( Settings
        , defaultEditorSettings
        , defaultSettings
        , settingsDecoder
        )
import Models.SettingsCache as SettingsCache
import Models.ShareState as ShareState
import Models.ShareToken as ShareToken
import Models.Size as Size exposing (Size)
import Models.Snackbar as SnackbarModel
import Models.Text as Text
import Models.Theme as Theme
import Models.Title as Title
import Models.Window as Window exposing (Window)
import Page.Embed as Embed
import Page.Help as Help
import Page.List as DiagramList
import Page.List.DiagramList as DiagramListModel
import Page.New as New
import Page.NotFound as NotFound
import Page.Settings as Settings
import Ports
import Return exposing (Return)
import Route exposing (Route(..), toRoute)
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
        , update = \msg m -> Return.singleton m |> update m msg
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
                                    |> DiagramModel.showZoomControl.set False
                                    |> DiagramModel.diagramType.set diagram
                                    |> DiagramModel.scale.set (Scale.fromFloat 1.0)
                                    |> DiagramModel.windowSize.set
                                        ( Maybe.withDefault (Size.getWidth m.diagramModel.windowSize) width
                                        , Maybe.withDefault (Size.getHeight m.diagramModel.windowSize) height
                                        )
                            , window = m.window |> Window.fullscreen
                        }
                )
                >> setTitle title
                >> Return.andThen (\m -> Return.singleton m |> Effect.loadShareItemWithoutPassword M.Load { session = m.session, token = id_ })
                >> switchPage Page.Embed
                >> Effect.changeRouteInit M.Init

        Route.ViewFile _ id_ ->
            ShareToken.unwrap id_
                |> Maybe.andThen Jwt.fromString
                |> Maybe.map
                    (\jwt ->
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
                                        |> Effect.loadShareItemWithoutPassword M.Load { session = m.session, token = id_ }
                                )
                                >> switchPage Page.Main
                                >> startProgress
                                >> Effect.changeRouteInit M.Init
                    )
                |> Maybe.withDefault (switchPage Page.NotFound)

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


showDialog : Dialog.ConfirmDialog Msg -> Maybe (Html Msg)
showDialog d =
    case d of
        Dialog.Hide ->
            Nothing

        Dialog.Show { title, message, ok, cancel } ->
            Just <|
                ConfirmDialog.view
                    { title = title
                    , message = message
                    , okButton = { text = "Ok", onClick = ok }
                    , cancelButton = { text = "Cancel", onClick = cancel }
                    }


showProgress : Bool -> Maybe (Html Msg)
showProgress show =
    if show then
        Just Progress.view

    else
        Nothing


setCurrentDiagram : DiagramItem -> Return.ReturnF Msg Model
setCurrentDiagram currentDiagram =
    Return.map <| \m -> { m | currentDiagram = currentDiagram }


moveTo : Route -> Return.ReturnF Msg Model
moveTo route =
    Return.andThen <| \m -> Return.singleton m |> Return.command (Route.moveTo m.key route)


needSaved : Return.ReturnF Msg Model
needSaved =
    Return.map <| \m -> { m | diagramModel = m.diagramModel |> DiagramModel.text.set (Text.change m.diagramModel.text) }


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
                |> DiagramList.update m.diagramListModel msg
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
            Return.singleton m.shareModel
                |> Share.update m.shareModel msg
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
                |> Diagram.update m.diagramModel (DiagramModel.ChangeText <| Text.toString diagram.text)
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
                | diagramModel = m.diagramModel |> DiagramModel.settings.set settings
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
    Return.map <| \m -> { m | diagramModel = m.diagramModel |> DiagramModel.text.set (Text.saved m.diagramModel.text) }


setTitle : String -> Return.ReturnF Msg Model
setTitle title =
    Return.map <| \m -> { m | currentDiagram = DiagramItem.title.set (Title.fromString <| title) m.currentDiagram }


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
                            |> DiagramItem.text.set newDiagramModel.text
                            |> DiagramItem.thumbnail.set Nothing
                            |> DiagramItem.location.set (Just location)
                            |> DiagramItem.diagram.set newDiagramModel.diagramType
                in
                Return.map
                    (\m_ ->
                        { m_
                            | diagramModel = newDiagramModel
                            , diagramListModel = m_.diagramListModel |> DiagramList.diagramList.set DiagramListModel.notAsked
                        }
                    )
                    >> (case ( location, Session.loginProvider m.session ) of
                            ( DiagramLocation.Gist, Just (LoginProvider.Github Nothing) ) ->
                                Effect.getGistTokenAfterSave

                            ( DiagramLocation.Gist, _ ) ->
                                Effect.saveDiagram diagram

                            ( DiagramLocation.Remote, _ ) ->
                                Effect.saveDiagram diagram

                            ( DiagramLocation.LocalFileSystem, _ ) ->
                                Return.zero

                            ( DiagramLocation.Local, _ ) ->
                                Effect.saveDiagram diagram
                       )
               )
    )
        |> Return.andThen


signIn : Session.User -> Return.ReturnF Msg Model
signIn user =
    Return.map (\m -> { m | session = Session.signIn user })


signOut : Return.ReturnF Msg Model
signOut =
    Return.map (\m -> { m | session = Session.guest })



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
         , Ports.hotkey (\cmd -> M.Hotkey <| Hotkey.fromString cmd)
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


update : Model -> Msg -> Return.ReturnF Msg Model
update model message =
    case message of
        M.NoOp ->
            Return.zero

        M.Init window ->
            (\m ->
                Return.singleton m.diagramModel
                    |> Diagram.update m.diagramModel (DiagramModel.Init m.diagramModel.settings window (Text.toString m.diagramModel.text))
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
            let
                ( diagramModel, diagramCmd ) =
                    Return.singleton model.diagramModel
                        |> Diagram.update model.diagramModel subMsg
                        |> Return.mapBoth M.UpdateDiagram (\m -> { model | diagramModel = m })
            in
            (case subMsg of
                DiagramModel.ToggleFullscreen ->
                    Return.map
                        (\m ->
                            { m
                                | diagramModel = diagramModel.diagramModel
                                , window = windowState m.window diagramModel.diagramModel.diagram.isFullscreen diagramModel.diagramModel.windowSize
                            }
                        )
                        >> Effect.toggleFullscreen model.window

                DiagramModel.Resize _ _ ->
                    updateWindowState

                _ ->
                    Return.zero
            )
                >> Return.map (\m -> { m | diagramModel = diagramModel.diagramModel })
                >> Return.command diagramCmd

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
                                    | diagramModel = m.diagramModel |> DiagramModel.settings.set model_.settings.storyMap
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
            pushUrl (Route.toString <| Edit model.currentDiagram.diagram)
                >> startProgress
                >> Effect.closeLocalFile
                >> (DiagramItem.copy model.currentDiagram
                        |> M.Copied
                        |> Utils.delay 100
                        |> Return.command
                   )

        M.Copied diagram ->
            loadDiagram diagram

        M.Download exportDiagram ->
            let
                ( posX, posY ) =
                    model.diagramModel.diagram.position
            in
            Exporter.export
                exportDiagram
                { data = model.diagramModel.data
                , diagramType = model.diagramModel.diagramType
                , items = model.diagramModel.items
                , size =
                    DiagramModel.size model.diagramModel
                        |> Tuple.mapBoth (\x -> x + posX) (\y -> y + posY)
                , text = model.diagramModel.text
                , title = model.currentDiagram.title
                }
                |> Maybe.map Return.command
                |> Maybe.withDefault Return.zero

        M.DownloadCompleted ( x, y ) ->
            Return.map (\m -> { m | diagramModel = m.diagramModel |> DiagramModel.position.set ( x, y ) })

        M.StartDownload info ->
            Return.command (Download.string (Title.toString model.currentDiagram.title ++ info.extension) info.mimeType info.content)
                >> closeMenu

        M.Save ->
            save

        M.SaveToRemoteCompleted (Ok diagram) ->
            (Maybe.withDefault (DiagramId.fromString "") diagram.id
                |> Route.EditFile diagram.diagram
                |> Route.replaceRoute model.key
                |> Return.command
            )
                >> setCurrentDiagram diagram
                >> stopProgress
                >> showInfoMessage Message.messageSuccessfullySaved

        M.SaveToRemoteCompleted (Err _) ->
            let
                item : DiagramItem
                item =
                    model.currentDiagram
                        |> DiagramItem.text.set model.diagramModel.text
                        |> DiagramItem.thumbnail.set Nothing
                        |> DiagramItem.location.set (Just DiagramLocation.Local)
                        |> DiagramItem.diagram.set model.diagramModel.diagramType
            in
            setCurrentDiagram item
                >> Effect.saveToLocal item
                >> stopProgress
                >> showWarningMessage Message.messageFailedSaved

        M.SaveToLocalCompleted diagramJson ->
            D.decodeValue DiagramItem.decoder diagramJson
                |> Result.toMaybe
                |> Maybe.map
                    (\item ->
                        setCurrentDiagram item
                            >> (Maybe.withDefault (DiagramId.fromString "") item.id
                                    |> Route.EditLocalFile item.diagram
                                    |> Route.replaceRoute model.key
                                    |> Return.command
                               )
                            >> showInfoMessage Message.messageSuccessfullySaved
                    )
                |> Maybe.withDefault Return.zero

        M.SaveToRemote diagramJson ->
            D.decodeValue DiagramItem.decoder diagramJson
                |> Result.toMaybe
                |> Maybe.map
                    (\d ->
                        Effect.saveToRemote M.SaveToRemoteCompleted
                            { diagram = d
                            , session = model.session
                            , settings = model.settingsModel.settings
                            }
                            >> startProgress
                    )
                |> Maybe.withDefault (showWarningMessage Message.messageSuccessfullySaved >> stopProgress)

        M.StartEditTitle ->
            Return.map (\m -> { m | currentDiagram = DiagramItem.title.set (Title.edit m.currentDiagram.title) m.currentDiagram })
                >> Effect.setFocus M.NoOp "title"

        M.Progress visible ->
            Return.map <| \m -> { m | progress = visible }

        M.EndEditTitle ->
            Return.map (\m -> { m | currentDiagram = DiagramItem.title.set (Title.view m.currentDiagram.title) m.currentDiagram })
                >> Effect.setFocusEditor

        M.EditTitle title ->
            Return.map (\m -> { m | currentDiagram = DiagramItem.title.set (Title.edit <| Title.fromString title) m.currentDiagram })
                >> needSaved

        M.SignIn provider ->
            Return.command (Ports.signIn <| LoginProvider.toString provider)
                >> startProgress

        M.SignOut ->
            Effect.revokeGistToken M.CallApi model.session
                >> Return.command (Ports.signOut ())
                >> setCurrentDiagram DiagramItem.empty
                >> signOut

        M.LinkClicked (Browser.Internal url) ->
            if Text.isChanged model.diagramModel.text then
                showConfirmDialog "Confirmation" "Your data has been changed. do you wish to continue?" (toRoute url)

            else
                case toRoute model.url of
                    Route.Settings diagramType ->
                        pushUrl (Url.toString url)
                            >> Effect.saveDiagramSettings M.SaveDiagramSettings
                                { session = model.session
                                , diagramType = diagramType
                                , settings = model.settingsModel.settings
                                }
                            >> setDiagramSettingsCache model.settingsModel.settings.storyMap

                    _ ->
                        pushUrl (Url.toString url)

        M.LinkClicked (Browser.External href) ->
            Return.command <| Nav.load href

        M.UrlChanged url ->
            Return.map (\m -> { m | url = url, prevRoute = Just <| toRoute m.url }) >> changeRouteTo (toRoute url)

        M.HandleVisibilityChange Hidden ->
            let
                newSettings : Settings
                newSettings =
                    { position = Just model.window.position
                    , font = model.settingsModel.settings.font
                    , diagramId = Maybe.map DiagramId.toString model.currentDiagram.id
                    , storyMap =
                        DiagramSettings.ofScale.set
                            (model.diagramModel.diagram.scale
                                |> Scale.toFloat
                                |> Just
                            )
                            newStoryMap.storyMap
                    , text = Just (Text.toString model.diagramModel.text)
                    , title = Just <| Title.toString model.currentDiagram.title
                    , editor = model.settingsModel.settings.editor
                    , diagram = Just model.currentDiagram
                    , location = model.settingsModel.settings.location
                    , theme = model.settingsModel.settings.theme
                    }

                ( newSettingsModel, _ ) =
                    Settings.init
                        { canUseNativeFileSystem = model.browserStatus.canUseNativeFileSystem
                        , diagramType = model.currentDiagram.diagram
                        , session = model.session
                        , settings = newSettings
                        , lang = model.lang
                        , usableFontList =
                            BoolEx.toMaybe model.settingsModel.usableFontList
                                (Settings.isFetchedUsableFont model.settingsModel)
                        }

                newStoryMap : Settings
                newStoryMap =
                    model.settingsModel.settings |> Settings.font.set model.settingsModel.settings.font
            in
            Return.map (\m -> { m | settingsModel = newSettingsModel })
                >> Effect.saveSettingsToLocal newSettings

        M.HandleVisibilityChange _ ->
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
            D.decodeValue Session.decoder value
                |> Result.toMaybe
                |> Maybe.map
                    (\user ->
                        signIn user
                            >> (case toRoute model.url of
                                    Route.EditFile type_ id_ ->
                                        BoolEx.ifElse
                                            (pushUrl (Route.toString <| Route.EditFile type_ id_))
                                            Return.zero
                                            (DiagramItem.getId model.currentDiagram /= id_)

                                    Route.DiagramList ->
                                        pushUrl (Route.toString <| Route.Home)

                                    Route.ViewFile _ id_ ->
                                        ShareToken.unwrap id_
                                            |> Maybe.andThen Jwt.fromString
                                            |> Maybe.map
                                                (\jwt ->
                                                    BoolEx.ifElse (switchPage Page.Main >> Effect.changeRouteInit M.Init)
                                                        (switchPage Page.Main
                                                            >> Effect.loadShareItemWithoutPassword M.Load { session = model.session, token = id_ }
                                                            >> startProgress
                                                            >> Effect.changeRouteInit M.Init
                                                        )
                                                        jwt.checkPassword
                                                )
                                            |> Maybe.withDefault (switchPage Page.NotFound)

                                    _ ->
                                        Return.zero
                               )
                            >> stopProgress
                    )
                |> Maybe.withDefault (Return.map (\m -> { m | session = Session.guest }) >> stopProgress)

        M.HandleAuthStateChanged Nothing ->
            Return.map (\m -> { m | session = Session.guest })
                >> moveTo Route.Home
                >> stopProgress

        M.ShowNotification notification ->
            Return.map <| \m -> { m | notification = notification }

        M.SwitchWindow w ->
            Return.map <| \m -> { m | window = Window.toggle w }

        M.Hotkey (Just (Hotkey.Open _)) ->
            Route.toString Route.DiagramList
                |> Nav.load
                |> Return.command

        M.Hotkey (Just (Hotkey.Save _)) ->
            BoolEx.ifElse
                save
                Return.zero
                (Text.isChanged model.diagramModel.text)

        M.Hotkey (Just (Hotkey.Find _)) ->
            (\m ->
                Return.singleton m.diagramModel
                    |> Diagram.update m.diagramModel DiagramModel.ToggleSearch
                    |> Return.mapBoth M.UpdateDiagram (\m_ -> { m | diagramModel = m_ })
            )
                >> Effect.setFocus M.NoOp "diagram-search"
                |> Return.andThen

        M.Hotkey _ ->
            Return.zero

        M.GotLocalDiagramJson json ->
            D.decodeValue DiagramItem.decoder json
                |> Result.toMaybe
                |> Maybe.map (Effect.loadText M.Load)
                |> Maybe.withDefault Return.zero

        M.ChangePublicStatus isPublic ->
            Effect.updateIdToken
                >> Effect.changePublicState M.ChangePublicStatusCompleted
                    { isPublic = isPublic
                    , item = model.currentDiagram
                    , session = model.session
                    }
                >> stopProgress

        M.ChangePublicStatusCompleted (Ok d) ->
            setCurrentDiagram d
                >> stopProgress
                >> showInfoMessage Message.messagePublished

        M.ChangePublicStatusCompleted (Err _) ->
            showErrorMessage Message.messageFailedPublished
                >> stopProgress

        M.Load (Ok diagram) ->
            loadDiagram diagram

        M.Load (Err (RequestError.NotFound as e)) ->
            moveTo Route.NotFound
                >> showErrorMessage (RequestError.toMessage e)
                >> stopProgress

        M.Load (Err e) ->
            showErrorMessage (RequestError.toMessage e)
                >> stopProgress

        M.LoadSettings (Ok settings) ->
            setDiagramSettings settings >> stopProgress

        M.LoadSettings (Err _) ->
            setDiagramSettings (.storyMap (defaultSettings (Theme.System model.browserStatus.isDarkMode)))
                >> stopProgress

        M.LoadSettingsFromLocal settingsJson ->
            D.decodeValue settingsDecoder settingsJson
                |> Result.toMaybe
                |> Maybe.map
                    (\settings ->
                        Return.map
                            (\m ->
                                let
                                    ( newSettingsModel, _ ) =
                                        Settings.init
                                            { canUseNativeFileSystem = m.browserStatus.canUseNativeFileSystem
                                            , diagramType = m.currentDiagram.diagram
                                            , session = m.session
                                            , settings = settings
                                            , lang = m.lang
                                            , usableFontList = BoolEx.toMaybe m.settingsModel.usableFontList (Settings.isFetchedUsableFont m.settingsModel)
                                            }
                                in
                                { m | settingsModel = newSettingsModel, diagramModel = DiagramModel.settings.set settings.storyMap m.diagramModel }
                            )
                    )
                |> Maybe.withDefault (showWarningMessage Message.messageFailedLoadSettings)

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
            (\m ->
                Return.singleton m.diagramModel
                    |> Diagram.update m.diagramModel DiagramModel.ToggleFullscreen
                    |> Return.mapBoth M.UpdateDiagram
                        (\m_ ->
                            { m
                                | diagramModel = m_
                                , window =
                                    BoolEx.ifElse Window.showEditor
                                        Window.showEditorAndPreview
                                        (Utils.isPhone (Size.getWidth m.diagramModel.windowSize))
                                        m.window
                            }
                        )
            )
                |> Return.andThen

        M.UpdateIdToken token ->
            Return.map <| \m -> { m | session = Session.updateIdToken m.session (IdToken.fromString token) }

        M.EditPassword password ->
            Return.map <| \m -> { m | shareState = ShareState.inputPassword m.shareState password }

        M.EndEditPassword ->
            ShareState.getToken model.shareState
                |> Maybe.map
                    (\t ->
                        switchPage Page.Main
                            >> Effect.loadShareItem M.LoadWithPassword
                                { password = ShareState.getPassword model.shareState
                                , session = model.session
                                , token = t
                                }
                            >> startProgress
                    )
                |> Maybe.withDefault Return.zero

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
            Return.map (\m -> { m | session = Session.updateAccessToken m.session (accessToken |> Maybe.withDefault "") })
                >> BoolEx.ifElse (Effect.loadItem M.Load { id = DiagramId.fromString cmd, session = model.session })
                    (Return.command (Task.perform identity (Task.succeed M.Save)))
                    (not <| String.isEmpty cmd)

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
            Return.andThen <| \m -> Return.singleton m |> Effect.saveLocalFile (DiagramItem.text.set (Text.saved m.diagramModel.text) m.currentDiagram)

        M.SavedLocalFile title ->
            Return.andThen <| \m -> Return.singleton m |> loadDiagram (DiagramItem.localFile title <| Text.toString m.diagramModel.text)

        M.ChangeDiagramType diagramType ->
            Return.map (\m -> { m | diagramModel = m.diagramModel |> DiagramModel.diagramType.set diagramType })
                >> loadDiagram (model.currentDiagram |> DiagramItem.diagram.set diagramType)

        M.OpenCurrentFile ->
            openCurrentFile model.currentDiagram


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


headerView : Model -> Html Msg
headerView model =
    if Window.isFullscreen model.window then
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
            , onMoveTo = M.MoveTo
            , onStartEditTitle = M.StartEditTitle
            , onEditTitle = M.EditTitle
            , onEndEditTitle = M.EndEditTitle
            , onChangePublicStatus = M.ChangePublicStatus
            , onOpenMenu = M.OpenMenu
            , onCloseMenu = M.CloseMenu
            , onSignIn = M.SignIn
            , onSignOut = M.SignOut
            }


menuView : Model -> Html Msg
menuView model =
    if Route.isViewFile (toRoute model.url) || Window.isFullscreen model.window then
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
            , onOpenLocalFile = M.OpenLocalFile
            , onOpenMenu = M.OpenMenu
            , onCopy = M.Copy
            , onDownload = M.Download
            , onSaveLocalFile = M.SaveLocalFile
            , onSave = M.Save
            , onOpenCurrentFile = M.OpenCurrentFile
            }


mainView : Model -> Html Msg
mainView model =
    case toRoute model.url of
        ViewFile _ id_ ->
            ShareToken.unwrap id_
                |> Maybe.andThen Jwt.fromString
                |> Maybe.map
                    (\jwt ->
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
                            Html.div [ Attr.css [ Style.full, backgroundColor <| Css.hex model.settingsModel.settings.storyMap.backgroundColor ] ]
                                [ Lazy.lazy Diagram.view model.diagramModel
                                    |> Html.map M.UpdateDiagram
                                ]
                    )
                |> Maybe.withDefault NotFound.view

        _ ->
            if Size.getWidth model.diagramModel.windowSize > 0 && Utils.isPhone (Size.getWidth model.diagramModel.windowSize) then
                Lazy.lazy3 SwitchWindow.view
                    { onSwitchWindow = M.SwitchWindow
                    , bgColor = Css.hex model.diagramModel.settings.backgroundColor
                    , window = model.window
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
                    (Lazy.lazy Diagram.view model.diagramModel
                        |> Html.map M.UpdateDiagram
                    )

            else
                Lazy.lazy3 SplitWindow.view
                    { bgColor = Css.hex model.diagramModel.settings.backgroundColor
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
                    (Lazy.lazy Diagram.view model.diagramModel
                        |> Html.map M.UpdateDiagram
                    )


view : Model -> Html Msg
view model =
    Html.main_
        [ Attr.css [ position relative, Style.widthScreen ]
        , E.onClick M.CloseMenu
        ]
        ([ GlobalStyle.style
         , headerView model
         , Lazy.lazy Notification.view model.notification
         , Lazy.lazy Snackbar.view model.snackbar
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
            [ menuView model
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
                    mainView model
            ]
         , case toRoute model.url of
            Share ->
                Lazy.lazy Share.view model.shareModel |> Html.map M.UpdateShare

            ViewFile _ id_ ->
                ShareToken.unwrap id_
                    |> Maybe.andThen Jwt.fromString
                    |> Maybe.map
                        (\jwt ->
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
                        )
                    |> Maybe.withDefault Empty.view

            _ ->
                Empty.view
         , Lazy.lazy Footer.view
            { diagramType = model.currentDiagram.diagram
            , currentDiagram = model.currentDiagram
            , session = model.session
            , onChangeDiagramType = M.ChangeDiagramType
            }
         ]
            ++ ([ showProgress model.progress
                , showDialog model.confirmDialog
                ]
                    |> List.filterMap identity
               )
        )


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
