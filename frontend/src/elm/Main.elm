module Main exposing (Flags, main)

import Api.RequestError
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
import Css
import Diagram.Effect
import Diagram.Lens
import Diagram.State
import Diagram.Types
import Diagram.Types.Id
import Diagram.Types.Item as DiagramItem exposing (DiagramItem)
import Diagram.Types.Location as DiagramLocation exposing (Location)
import Diagram.Types.Scale as Scale exposing (Scale)
import Diagram.Types.Settings as DiagramSettings
import Diagram.Types.Type as DiagramType exposing (DiagramType(..))
import Diagram.View as DiagramView
import Dialog.Confirm
import Dialog.Input
import Dialog.Share
import Dialog.Types as Dialog
import Effect
import Effect.Settings
import Env
import File.Download as Download
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes as Attr
import Html.Styled.Events as E
import Html.Styled.Lazy as Lazy
import Json.Decode as D
import Message exposing (Message)
import Page.Embed
import Page.Help
import Page.List
import Page.List.DiagramList
import Page.New
import Page.NotFound
import Page.Settings
import Page.Types as Page exposing (Page)
import Ports
import Return exposing (Return)
import Route exposing (Route(..), toRoute)
import String
import Style.Breakpoint as Breakpoint
import Style.Color
import Style.Font
import Style.Global
import Style.Style as Style
import Style.Text
import Task
import Types as M exposing (Model, Msg)
import Types.Color as Color
import Types.Export.Diagram as ExportDiagram
import Types.FontSize as FontSize
import Types.Hotkey as Hotkey
import Types.IdToken as IdToken
import Types.Jwt as Jwt
import Types.LoginProvider as LoginProvider
import Types.Notification as Notification
import Types.Session as Session
import Types.Settings as Settings
    exposing
        ( Settings
        , defaultEditorSettings
        , defaultSettings
        )
import Types.SettingsCache as SettingsCache
import Types.ShareState as ShareState
import Types.ShareToken as ShareToken
import Types.Size as Size exposing (Size)
import Types.Snackbar as SnackbarModel
import Types.SplitDirection as SplitDirection
import Types.Text as Text
import Types.Theme as Theme
import Types.Title as Title
import Types.UrlEncodedText as UrlEncodedText
import Types.Window as Window exposing (Window)
import Url
import Utils.Common as Utils
import View.Empty as Empty
import View.Footer as Footer
import View.Header as Header
import View.Menu as Menu
import View.Notification as Notification
import View.Progress as Progress
import View.Snackbar as Snackbar
import View.SplitWindow as SplitWindow
import View.SwitchWindow as SwitchWindow


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

        Route.Edit _ (Just copyDiagramId) (Just isRemote) ->
            switchPage Page.Main
                >> Return.andThen
                    (\m ->
                        Return.singleton m
                            |> (if Session.isSignedIn m.session && m.browserStatus.isOnline && isRemote then
                                    Effect.updateIdToken
                                        >> startProgress
                                        >> Diagram.Effect.load M.Copied { id = copyDiagramId, session = m.session }

                                else
                                    Diagram.Effect.loadFromLocalForCopy copyDiagramId >> Effect.changeRouteInit M.Init
                               )
                            |> Effect.Settings.load M.LoadSettings { cache = m.settingsCache, diagramType = m.currentDiagram.diagram, session = m.session }
                    )

        Route.Edit diagramType _ _ ->
            setCurrentDiagram (DiagramItem.new diagramType)
                >> startProgress
                >> Return.andThen (\m -> Return.singleton m |> Effect.Settings.load M.LoadSettings { cache = m.settingsCache, diagramType = m.currentDiagram.diagram, session = m.session })
                >> loadDiagram (DiagramItem.new diagramType)
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
                                        >> Diagram.Effect.load M.Load { id = id_, session = m.session }

                                else
                                    Diagram.Effect.loadFromLocal id_ >> Effect.changeRouteInit M.Init
                               )
                            |> Effect.Settings.load M.LoadSettings { cache = m.settingsCache, diagramType = m.currentDiagram.diagram, session = m.session }
                    )

        Route.EditLocalFile _ id_ ->
            switchPage Page.Main
                >> Diagram.Effect.loadFromLocal id_
                >> Effect.changeRouteInit M.Init

        Route.ViewPublic _ id_ ->
            Effect.updateIdToken
                >> switchPage Page.Main
                >> Return.andThen (\m -> Return.singleton m |> Diagram.Effect.loadFromPublic M.Load { id = id_, session = m.session })

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
                                    |> Diagram.Types.showZoomControl.set False
                                    |> Diagram.Types.diagramType.set diagram
                                    |> Diagram.Types.windowSize.set
                                        ( Maybe.withDefault (Size.getWidth m.diagramModel.windowSize) width
                                        , Maybe.withDefault (Size.getHeight m.diagramModel.windowSize) height
                                        )
                            , window = m.window |> Window.fullscreen
                        }
                )
                >> setTitle title
                >> Return.andThen (\m -> Return.singleton m |> Diagram.Effect.loadFromShareWithoutPassword M.Load { session = m.session, token = id_ })
                >> switchPage Page.Embed
                >> Effect.changeRouteInit M.Init

        Route.ViewFile _ id_ ->
            ShareToken.unwrap id_
                |> Maybe.andThen Jwt.fromString
                |> Maybe.map
                    (\jwt ->
                        if jwt.checkPassword || jwt.checkEmail then
                            Return.andThen (\m -> Return.singleton { m | shareState = ShareState.authenticateWithPassword id_ })
                                >> switchPage Page.Main
                                >> Effect.changeRouteInit M.Init

                        else
                            Return.andThen
                                (\m ->
                                    Return.singleton
                                        { m | shareState = ShareState.authenticateNoPassword id_ }
                                        |> Diagram.Effect.loadFromShareWithoutPassword M.Load { session = m.session, token = id_ }
                                )
                                >> switchPage Page.Main
                                >> startProgress
                                >> Effect.changeRouteInit M.Init
                    )
                |> Maybe.withDefault (switchPage Page.NotFound)

        Route.Preview type_ text_ ->
            loadDiagram
                (DiagramItem.new type_
                    |> DiagramItem.text.set
                        (UrlEncodedText.toText text_
                            |> Text.map (\t -> "# zoom_control: false\n# toolbar: false\n" ++ t)
                        )
                )
                >> fullscreen
                >> switchPage Page.Main
                >> Effect.changeRouteInit M.Init

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
            , Attr.attribute "fontSize" <| String.fromInt <| FontSize.unwrap <| .fontSize <| defaultEditorSettings model.settingsModel.settings.editor
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
            , Attributes.dataTestId "editor"
            ]
            []
        ]


init : Flags -> Url.Url -> Nav.Key -> Return Msg Model
init flags url key =
    let
        currentDiagram : DiagramItem
        currentDiagram =
            initSettings.diagram |> Maybe.withDefault DiagramItem.empty

        initSettings : Settings
        initSettings =
            D.decodeValue Settings.decoder flags.settings
                |> Result.withDefault (defaultSettings (Theme.System flags.isDarkMode))

        lang : Message.Lang
        lang =
            Message.langFromString flags.lang

        model : Model
        model =
            { key = key
            , url = url
            , page = Page.Main
            , diagramModel =
                Diagram.State.init initSettings.diagramSettings
                    |> Tuple.first
                    |> Diagram.Lens.text.set (Maybe.withDefault Text.empty initSettings.text)
            , diagramListModel = Page.List.init Session.guest lang Env.apiRoot flags.isOnline |> Tuple.first
            , settingsModel =
                Page.Settings.init
                    { canUseNativeFileSystem = flags.canUseNativeFileSystem
                    , diagramType = currentDiagram.diagram
                    , session = Session.guest
                    , settings = initSettings
                    , lang = lang
                    , usableFontList = Just []
                    }
                    |> Tuple.first
            , shareModel =
                Dialog.Share.init
                    { diagram = UserStoryMap
                    , diagramId = Diagram.Types.Id.fromString ""
                    , session = Session.guest
                    , title = Title.untitled
                    }
                    |> Tuple.first
            , session = Session.guest
            , currentDiagram = { currentDiagram | title = Maybe.withDefault Title.untitled initSettings.title }
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
    in
    Return.singleton model |> changeRouteTo (toRoute url)


showDialog : Dialog.ConfirmDialog Msg -> Maybe (Html Msg)
showDialog d =
    case d of
        Dialog.Hide ->
            Nothing

        Dialog.Show { title, message, ok, cancel } ->
            Just <|
                Dialog.Confirm.view
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
    Return.map <| \m -> { m | diagramModel = m.diagramModel |> Diagram.Types.text.set (Text.change m.diagramModel.text) }


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
                |> Page.List.load { session = m.session, isOnline = m.browserStatus.isOnline }
                |> Return.mapBoth M.UpdateDiagramList (\m_ -> { m | diagramListModel = m_ })


updateListPage : Page.List.Msg -> Return.ReturnF Msg Model
updateListPage msg =
    Return.andThen <|
        \m ->
            Return.singleton m.diagramListModel
                |> Page.List.update m.diagramListModel msg
                |> Return.mapBoth M.UpdateDiagramList (\m_ -> { m | diagramListModel = m_ })


initSettingsPage : DiagramType -> Return.ReturnF Msg Model
initSettingsPage diagramType =
    Return.andThen <|
        \m ->
            Return.singleton m.settingsModel
                |> Page.Settings.load { diagramType = diagramType, session = m.session }
                |> Return.mapBoth M.UpdateSettings (\m_ -> { m | settingsModel = m_ })


initShareDiagram : DiagramItem -> Return.ReturnF Msg Model
initShareDiagram diagramItem =
    Return.andThen <|
        \m ->
            Dialog.Share.init
                { diagram = diagramItem.diagram
                , diagramId = diagramItem.id |> Maybe.withDefault (Diagram.Types.Id.fromString "")
                , session = m.session
                , title = m.currentDiagram.title
                }
                |> Return.mapBoth M.UpdateShare (\m_ -> { m | shareModel = m_ })


updateShareDiagram : Dialog.Share.Msg -> Return.ReturnF Msg Model
updateShareDiagram msg =
    Return.andThen <|
        \m ->
            Return.singleton m.shareModel
                |> Dialog.Share.update m.shareModel msg
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
                |> closeNotification


loadDiagram : DiagramItem -> Return.ReturnF Msg Model
loadDiagram diagram =
    Return.andThen <|
        \m ->
            m.diagramModel
                |> Diagram.Types.diagramType.set diagram.diagram
                |> Diagram.Types.text.set diagram.text
                |> Return.singleton
                |> Diagram.State.update m.diagramModel (Diagram.Types.ChangeText <| Text.toString diagram.text)
                |> Return.mapBoth M.UpdateDiagram (\m_ -> m |> M.currentDiagram.set diagram |> M.diagramModel.set m_)
                |> stopProgress


setDiagramSettings : DiagramSettings.Settings -> Return.ReturnF Msg Model
setDiagramSettings settings =
    Return.map
        (\m ->
            { m
                | diagramModel = m.diagramModel |> Diagram.Types.settings.set settings
                , settingsModel = m.settingsModel |> Page.Settings.diagramSettings.set settings
            }
        )
        >> setDiagramSettingsCache settings


setDiagramSettingsCache : DiagramSettings.Settings -> Return.ReturnF Msg Model
setDiagramSettingsCache settings =
    Return.map <| \m -> { m | settingsCache = SettingsCache.set m.settingsCache m.currentDiagram.diagram settings }


fullscreen : Return.ReturnF Msg Model
fullscreen =
    Return.map <| \m -> { m | window = m.window |> Window.fullscreen }


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
    Return.map <| \m -> { m | diagramModel = m.diagramModel |> Diagram.Types.text.set (Text.saved m.diagramModel.text) }


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

                    newDiagramModel : Diagram.Types.Model
                    newDiagramModel =
                        Diagram.Types.updatedText m.diagramModel (Text.saved m.diagramModel.text)

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
                            , diagramListModel = m_.diagramListModel |> Page.List.diagramList.set Page.List.DiagramList.notAsked
                        }
                    )
                    >> (case ( location, Session.loginProvider m.session ) of
                            ( DiagramLocation.Gist, Just (LoginProvider.Github Nothing) ) ->
                                Effect.getGistTokenAfterSave

                            ( DiagramLocation.Gist, _ ) ->
                                Diagram.Effect.save diagram

                            ( DiagramLocation.Remote, _ ) ->
                                Diagram.Effect.save diagram

                            ( DiagramLocation.LocalFileSystem, _ ) ->
                                Return.zero

                            ( DiagramLocation.Local, _ ) ->
                                Diagram.Effect.save diagram
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
        ([ Ports.changeText (\text -> M.UpdateDiagram (Diagram.Types.ChangeText text))
         , Ports.selectItemFromLineNo (\{ lineNo, text } -> M.UpdateDiagram (Diagram.Types.SelectFromLineNo lineNo text))
         , Ports.loadSettingsFromLocalCompleted M.LoadSettingsFromLocal
         , Ports.startDownload M.StartDownload
         , Ports.gotLocalDiagramsJson (\json -> M.UpdateDiagramList (Page.List.GotLocalDiagramsJson json))
         , Ports.removedLocalDiagram (\idString -> (Ok <| Diagram.Types.Id.fromString idString) |> Page.List.Removed |> M.UpdateDiagramList)
         , Ports.reload (\_ -> M.UpdateDiagramList Page.List.Reload)
         , onVisibilityChange M.HandleVisibilityChange
         , onResize (\width height -> M.UpdateDiagram (Diagram.Types.Resize width height))
         , Ports.hotkey (\cmd -> M.Hotkey <| Hotkey.fromString cmd)
         , Ports.onNotification (\n -> M.HandleAutoCloseNotification (Notification.showInfoNotifcation n))
         , Ports.sendErrorNotification (\n -> M.HandleAutoCloseNotification (Notification.showErrorNotifcation n))
         , Ports.onWarnNotification (\n -> M.HandleAutoCloseNotification (Notification.showWarningNotifcation n))
         , Ports.onAuthStateChanged M.HandleAuthStateChanged
         , Ports.saveToRemote M.SaveToRemote
         , Ports.removeRemoteDiagram (\diagram -> M.UpdateDiagramList <| Page.List.RemoveRemote diagram)
         , Ports.downloadCompleted M.DownloadCompleted
         , Ports.progress M.Progress
         , Ports.saveToLocalCompleted M.SaveToLocalCompleted
         , Ports.gotLocalDiagramJson M.GotLocalDiagramJson
         , Ports.gotLocalDiagramJsonForCopy M.GotLocalDiagramJsonForCopy
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
                    , case model.settingsModel.settings.splitDirection of
                        Just SplitDirection.Vertical ->
                            onMouseMove <| D.map M.HandleWindowResize (D.field "pageY" D.int)

                        _ ->
                            onMouseMove <| D.map M.HandleWindowResize (D.field "pageX" D.int)
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
                    |> Diagram.State.update m.diagramModel (Diagram.Types.Init m.diagramModel.settings window (Text.toString m.diagramModel.text))
                    |> Return.map
                        (\m_ ->
                            case toRoute m.url of
                                Route.Embed _ _ _ (Just w) (Just h) ->
                                    let
                                        scale : Maybe Scale
                                        scale =
                                            toFloat w
                                                / toFloat (Size.getWidth m_.diagram.size)
                                                |> Scale.fromFloat
                                                |> Just
                                    in
                                    { m_
                                        | windowSize = ( w, h )
                                        , diagram =
                                            { size = ( w, h )
                                            , position = m_.diagram.position
                                            , isFullscreen = m_.diagram.isFullscreen
                                            }
                                        , settings = m_.settings |> DiagramSettings.scale.set scale
                                    }

                                _ ->
                                    m_
                        )
                    |> Return.mapBoth M.UpdateDiagram (\m_ -> { m | diagramModel = m_ })
                    |> (Task.succeed m.currentDiagram
                            |> Task.attempt M.Load
                            |> Return.command
                       )
                    |> updateWindowState
            )
                >> stopProgress
                |> Return.andThen

        M.UpdateDiagram subMsg ->
            let
                ( diagramModel, diagramCmd ) =
                    Return.singleton model.diagramModel
                        |> Diagram.State.update model.diagramModel subMsg
                        |> Return.mapBoth M.UpdateDiagram (\m -> { model | diagramModel = m })
            in
            (case subMsg of
                Diagram.Types.ToggleFullscreen ->
                    Return.map
                        (\m ->
                            { m
                                | diagramModel = diagramModel.diagramModel
                                , window = windowState m.window diagramModel.diagramModel.diagram.isFullscreen diagramModel.diagramModel.windowSize
                            }
                        )
                        >> Effect.toggleFullscreen model.window

                Diagram.Types.Resize _ _ ->
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
                        |> Page.Settings.update msg
                        |> Return.mapBoth M.UpdateSettings
                            (\m_ ->
                                { m
                                    | diagramModel = m.diagramModel |> Diagram.Types.settings.set m_.settings.diagramSettings
                                    , page = Page.Settings
                                    , settingsModel = m_
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

        M.Copied (Ok diagram) ->
            loadDiagram { diagram | id = Nothing, title = Title.fromString <| "Copy of " ++ Title.toString diagram.title }

        M.Copied (Err e) ->
            showErrorMessage (Api.RequestError.toMessage e)
                >> stopProgress

        M.Download exportDiagram ->
            let
                ( posX, posY ) =
                    model.diagramModel.diagram.position
            in
            ExportDiagram.export
                exportDiagram
                { data = model.diagramModel.data
                , diagramType = model.diagramModel.diagramType
                , items = model.diagramModel.items
                , size =
                    Diagram.Types.size model.diagramModel
                        |> Tuple.mapBoth (\x -> x + posX) (\y -> y + posY)
                , text = model.diagramModel.text
                , title = model.currentDiagram.title
                }
                |> Maybe.map Return.command
                |> Maybe.withDefault Return.zero

        M.DownloadCompleted ( x, y ) ->
            Return.map (\m -> { m | diagramModel = m.diagramModel |> Diagram.Types.position.set ( x, y ) })

        M.StartDownload info ->
            Return.command (Download.string (Title.toString model.currentDiagram.title ++ info.extension) info.mimeType info.content)
                >> closeMenu

        M.Save ->
            save

        M.SaveToRemoteCompleted (Ok diagram) ->
            (Maybe.withDefault (Diagram.Types.Id.fromString "") diagram.id
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
                >> Diagram.Effect.saveToLocal item
                >> stopProgress
                >> showWarningMessage Message.messageFailedSaved

        M.SaveToLocalCompleted diagramJson ->
            D.decodeValue DiagramItem.decoder diagramJson
                |> Result.toMaybe
                |> Maybe.map
                    (\item ->
                        setCurrentDiagram item
                            >> (Maybe.withDefault (Diagram.Types.Id.fromString "") item.id
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
                        Diagram.Effect.saveToRemote M.SaveToRemoteCompleted
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
                            >> Effect.Settings.save M.SaveDiagramSettings
                                { session = model.session
                                , diagramType = diagramType
                                , settings = model.settingsModel.settings
                                }
                            >> setDiagramSettingsCache model.settingsModel.settings.diagramSettings

                    _ ->
                        pushUrl (Url.toString url)

        M.LinkClicked (Browser.External href) ->
            Return.command <| Nav.load href

        M.UrlChanged url ->
            Return.map (\m -> { m | url = url, prevRoute = Just <| toRoute m.url }) >> changeRouteTo (toRoute url)

        M.HandleVisibilityChange Hidden ->
            let
                diagramSettings : Settings
                diagramSettings =
                    model.settingsModel.settings |> Settings.font.set model.settingsModel.settings.font

                newSettings : Settings
                newSettings =
                    { position = Just model.window.position
                    , font = model.settingsModel.settings.font
                    , diagramId = model.currentDiagram.id
                    , diagramSettings =
                        diagramSettings.diagramSettings
                            |> DiagramSettings.scale.set model.diagramModel.settings.scale
                            |> DiagramSettings.lockEditing.set model.diagramModel.settings.lockEditing
                            |> DiagramSettings.font.set model.settingsModel.settings.font
                    , text = Just model.diagramModel.text
                    , title = Just model.currentDiagram.title
                    , editor = model.settingsModel.settings.editor
                    , diagram = Just model.currentDiagram
                    , location = model.settingsModel.settings.location
                    , theme = model.settingsModel.settings.theme
                    , splitDirection = model.settingsModel.settings.splitDirection
                    }
            in
            Return.map
                (\m ->
                    { m
                        | settingsModel =
                            Page.Settings.init
                                { canUseNativeFileSystem = model.browserStatus.canUseNativeFileSystem
                                , diagramType = model.currentDiagram.diagram
                                , session = model.session
                                , settings = newSettings
                                , lang = model.lang
                                , usableFontList =
                                    BoolEx.toMaybe model.settingsModel.usableFontList
                                        (Page.Settings.isFetchedUsableFont model.settingsModel)
                                }
                                |> Tuple.first
                    }
                )
                >> Effect.Settings.saveToLocal newSettings

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
                                                            >> Diagram.Effect.loadFromShareWithoutPassword M.Load { session = model.session, token = id_ }
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
                    |> Diagram.State.update m.diagramModel Diagram.Types.ToggleSearch
                    |> Return.mapBoth M.UpdateDiagram (\m_ -> { m | diagramModel = m_ })
            )
                >> Effect.setFocus M.NoOp "diagram-search"
                |> Return.andThen

        M.Hotkey _ ->
            Return.zero

        M.GotLocalDiagramJson json ->
            D.decodeValue DiagramItem.decoder json
                |> Result.toMaybe
                |> Maybe.map
                    (\diagram ->
                        Task.succeed diagram
                            |> Task.attempt M.Load
                            |> Return.command
                    )
                |> Maybe.withDefault Return.zero

        M.GotLocalDiagramJsonForCopy json ->
            D.decodeValue DiagramItem.decoder json
                |> Result.toMaybe
                |> Maybe.map
                    (\diagram ->
                        Task.succeed diagram
                            |> Task.attempt M.Copied
                            |> Return.command
                    )
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

        M.Load (Err (Api.RequestError.NotFound as e)) ->
            moveTo Route.NotFound
                >> showErrorMessage (Api.RequestError.toMessage e)
                >> stopProgress

        M.Load (Err e) ->
            showErrorMessage (Api.RequestError.toMessage e)
                >> stopProgress

        M.LoadSettings (Ok settings) ->
            setDiagramSettings settings >> stopProgress

        M.LoadSettings (Err _) ->
            setDiagramSettings (.diagramSettings (defaultSettings (Theme.System model.browserStatus.isDarkMode)))
                >> stopProgress

        M.LoadSettingsFromLocal settingsJson ->
            D.decodeValue Settings.decoder settingsJson
                |> Result.toMaybe
                |> Maybe.map
                    (\settings ->
                        Return.map
                            (\m ->
                                { m
                                    | settingsModel =
                                        Page.Settings.init
                                            { canUseNativeFileSystem = m.browserStatus.canUseNativeFileSystem
                                            , diagramType = m.currentDiagram.diagram
                                            , session = m.session
                                            , settings = settings
                                            , lang = m.lang
                                            , usableFontList = BoolEx.toMaybe m.settingsModel.usableFontList (Page.Settings.isFetchedUsableFont m.settingsModel)
                                            }
                                            |> Tuple.first
                                    , diagramModel = Diagram.Types.settings.set settings.diagramSettings m.diagramModel
                                }
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
                    |> Diagram.State.update m.diagramModel Diagram.Types.ToggleFullscreen
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
                            >> Diagram.Effect.loadFromShare M.LoadWithPassword
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
                >> BoolEx.ifElse (Diagram.Effect.load M.Load { id = Diagram.Types.Id.fromString cmd, session = model.session })
                    (Return.command (Task.perform identity (Task.succeed M.Save)))
                    (not <| String.isEmpty cmd)

        M.ChangeNetworkState isOnline ->
            Return.map <| \m -> { m | browserStatus = m.browserStatus |> M.isOnline.set isOnline }

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
            Return.andThen <| \m -> Return.singleton m |> Diagram.Effect.saveToLocalFileSystem (DiagramItem.text.set (Text.saved m.diagramModel.text) m.currentDiagram)

        M.SavedLocalFile title ->
            Return.andThen <| \m -> Return.singleton m |> loadDiagram (DiagramItem.localFile title <| Text.toString m.diagramModel.text)

        M.ChangeDiagramType diagramType ->
            Return.map (\m -> { m | diagramModel = m.diagramModel |> Diagram.Types.diagramType.set diagramType })
                >> loadDiagram (model.currentDiagram |> DiagramItem.diagram.set diagramType)

        M.OpenCurrentFile ->
            openCurrentFile model.currentDiagram


processDiagramListMsg : Page.List.Msg -> Return.ReturnF Msg Model
processDiagramListMsg msg =
    case msg of
        Page.List.Select diagram ->
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

        Page.List.Copy diagram ->
            (case ( diagram.location, diagram.isPublic ) of
                ( Just DiagramLocation.Remote, True ) ->
                    pushUrl (Route.toString <| Edit diagram.diagram (Just (DiagramItem.getId diagram)) (Just True))

                ( Just DiagramLocation.Remote, False ) ->
                    pushUrl (Route.toString <| Edit diagram.diagram (Just (DiagramItem.getId diagram)) (Just True))

                _ ->
                    pushUrl (Route.toString <| Edit diagram.diagram (Just (DiagramItem.getId diagram)) (Just False))
            )
                >> startProgress
                >> Effect.closeLocalFile

        Page.List.Export ->
            startProgress

        Page.List.GotExportDiagrams (Err e) ->
            showErrorMessage <| Api.RequestError.toMessage e

        Page.List.Removed (Ok diagramId) ->
            Return.map <|
                \m ->
                    if (m.currentDiagram.id |> Maybe.withDefault (Diagram.Types.Id.fromString "")) == diagramId then
                        { m | currentDiagram = DiagramItem.new DiagramType.UserStoryMap }

                    else
                        m

        Page.List.Removed (Err _) ->
            showErrorMessage Message.messagEerrorOccurred

        Page.List.GotDiagrams (Err _) ->
            showErrorMessage Message.messagEerrorOccurred

        Page.List.ImportDiagrams json ->
            case DiagramItem.stringToList json of
                Ok _ ->
                    showInfoMessage Message.messageImportCompleted

                Err _ ->
                    showErrorMessage Message.messagEerrorOccurred

        Page.List.ImportedRemoteDiagrams (Ok _) ->
            showInfoMessage Message.messageImportCompleted

        Page.List.ImportedRemoteDiagrams (Err _) ->
            showErrorMessage Message.messagEerrorOccurred

        _ ->
            stopProgress


updateSettings : Page.Settings.Msg -> DiagramType -> Return.ReturnF Msg Model
updateSettings msg diagramType =
    case msg of
        Page.Settings.UpdateSettings _ _ ->
            Return.andThen
                (\m ->
                    Return.singleton m
                        |> Effect.Settings.save M.SaveDiagramSettings
                            { diagramType = diagramType
                            , session = m.session
                            , settings = m.settingsModel.settings
                            }
                        |> setDiagramSettingsCache m.settingsModel.settings.diagramSettings
                )

        Page.Settings.LoadSettings (Ok settings) ->
            Return.andThen
                (\m ->
                    Return.singleton m
                        |> Effect.Settings.save M.SaveDiagramSettings
                            { diagramType = diagramType
                            , session = m.session
                            , settings = settings
                            }
                        |> setDiagramSettingsCache settings.diagramSettings
                )
                >> showInfoMessage Message.messageImportCompleted

        Page.Settings.LoadSettings (Err _) ->
            showErrorMessage Message.messagEerrorOccurred

        _ ->
            Return.zero


processShareMsg : Dialog.Share.Msg -> Return.ReturnF Msg Model
processShareMsg msg =
    Return.andThen <|
        \m ->
            Return.singleton m
                |> (case msg of
                        Dialog.Share.Shared (Err e) ->
                            showErrorMessage e

                        Dialog.Share.Close ->
                            Effect.historyBack m.key

                        Dialog.Share.LoadShareCondition (Err e) ->
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
                                    , Style.Text.xl
                                    , Style.Font.fontSemiBold
                                    , Style.widthScreen
                                    , Style.Color.textColor
                                    , Style.mSm
                                    , Css.height <| Css.calc (Css.vh 100) Css.minus (Css.px 40)
                                    ]
                                ]
                                [ Html.img
                                    [ Asset.src Asset.logo
                                    , Attr.css [ Css.width <| Css.px 32 ]
                                    , Attr.alt "NOT FOUND"
                                    ]
                                    []
                                , Html.div [ Attr.css [ Style.mSm ] ] [ Html.text "Sign in required" ]
                                ]

                        else
                            Html.div [ Attr.css [ Style.full, Css.backgroundColor <| Css.hex <| Color.toString model.settingsModel.settings.diagramSettings.backgroundColor ] ]
                                [ Lazy.lazy DiagramView.view model.diagramModel
                                    |> Html.map M.UpdateDiagram
                                ]
                    )
                |> Maybe.withDefault Page.NotFound.view

        _ ->
            if Size.getWidth model.diagramModel.windowSize > 0 && Utils.isPhone (Size.getWidth model.diagramModel.windowSize) then
                Lazy.lazy3 SwitchWindow.view
                    { onSwitchWindow = M.SwitchWindow
                    , bgColor = Css.hex <| Color.toString model.diagramModel.settings.backgroundColor
                    , window = model.window
                    }
                    (Html.div
                        [ Attr.css
                            [ Breakpoint.style
                                [ Style.hMain
                                , Style.widthFull
                                , Style.Color.bgMain
                                ]
                                [ Breakpoint.large [ Style.heightFull ] ]
                            ]
                        ]
                        [ editor model
                        ]
                    )
                    (Lazy.lazy DiagramView.view model.diagramModel
                        |> Html.map M.UpdateDiagram
                    )

            else
                Lazy.lazy3 SplitWindow.view
                    { bgColor = Css.hex <| Color.toString model.diagramModel.settings.backgroundColor
                    , window = model.window
                    , splitDirection = model.settingsModel.settings.splitDirection |> Maybe.withDefault SplitDirection.Horizontal
                    , onToggleEditor = M.ShowEditor
                    , onResize = M.HandleStartWindowResize
                    }
                    (Html.div
                        [ Attr.css
                            [ Breakpoint.style
                                [ case model.settingsModel.settings.splitDirection of
                                    Just SplitDirection.Horizontal ->
                                        Style.hMain

                                    _ ->
                                        Css.batch []
                                , Style.widthFull
                                , Style.Color.bgMain
                                ]
                                [ Breakpoint.large [ Style.heightFull ] ]
                            ]
                        ]
                        [ editor model
                        ]
                    )
                    (Lazy.lazy DiagramView.view model.diagramModel
                        |> Html.map M.UpdateDiagram
                    )


view : Model -> Html Msg
view model =
    Html.main_
        [ Attr.css [ Css.position Css.relative, Style.widthScreen ]
        , E.onClick M.CloseMenu
        ]
        ([ Style.Global.style
         , headerView model
         , Lazy.lazy Notification.view model.notification
         , Lazy.lazy Snackbar.view model.snackbar
         , Html.div
            [ Attr.css
                [ Css.displayFlex
                , Css.overflow Css.hidden
                , Css.position Css.relative
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
                    Page.New.view

                Page.Help ->
                    Page.Help.view

                Page.List ->
                    Lazy.lazy Page.List.view model.diagramListModel |> Html.map M.UpdateDiagramList

                Page.Settings ->
                    Lazy.lazy Page.Settings.view model.settingsModel |> Html.map M.UpdateSettings

                Page.Embed ->
                    Page.Embed.view model

                Page.NotFound ->
                    Page.NotFound.view

                _ ->
                    mainView model
            ]
         , case toRoute model.url of
            Share ->
                Lazy.lazy Dialog.Share.view model.shareModel |> Html.map M.UpdateShare

            ViewFile _ id_ ->
                ShareToken.unwrap id_
                    |> Maybe.andThen Jwt.fromString
                    |> Maybe.map
                        (\jwt ->
                            if jwt.checkPassword && not (ShareState.isAuthenticated model.shareState) then
                                Lazy.lazy Dialog.Input.view
                                    { title = "Protedted diagram"
                                    , errorMessage = Maybe.map Api.RequestError.toMessage (ShareState.getError model.shareState)
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
