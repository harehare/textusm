module Action exposing (..)

import Api.Http.Token as TokenApi
import Api.Request as Request
import Browser.Dom as Dom
import Browser.Navigation as Nav
import Components.Diagram as Diagram
import Dialog.Share as Share
import Graphql.Enum.Diagram exposing (Diagram)
import Graphql.OptionalArgument as OptionalArgument
import Message exposing (Message)
import Models.Diagram as DiagramModel
import Models.DiagramId as DiagramId exposing (DiagramId)
import Models.DiagramItem as DiagramItem exposing (DiagramItem)
import Models.DiagramLocation as DiagramLocation
import Models.Dialog exposing (ConfirmDialog(..))
import Models.LoginProvider as LoginProvider
import Models.Model exposing (Model, Msg(..))
import Models.Notification as Notification
import Models.Page exposing (Page)
import Models.Session as Session
import Models.ShareToken as ShareToken exposing (ShareToken)
import Models.Text as Text
import Models.Title as Title
import Page.List as DiagramList
import Page.Settings as SettingsPage
import Ports
import Return exposing (Return)
import Route exposing (Route)
import Settings
import Task
import Utils.Utils as Utils


loadText : DiagramItem.DiagramItem -> Model -> Return Msg Model
loadText diagram model =
    Return.return model (Task.attempt Load <| Task.succeed diagram)


loadLocalDiagram : DiagramId -> Model -> Return Msg Model
loadLocalDiagram diagramId model =
    Return.return model <| Ports.getDiagram (DiagramId.toString diagramId)


loadDiagram : DiagramItem -> Model -> Return Msg Model
loadDiagram diagram model =
    let
        diagramModel =
            model.diagramModel

        newDiagramModel =
            { diagramModel
                | diagramType = diagram.diagram
                , text = diagram.text
            }

        ( model_, cmd_ ) =
            Return.singleton newDiagramModel |> Diagram.update (DiagramModel.OnChangeText <| Text.toString diagram.text)
    in
    Return.return
        { model
            | title = diagram.title
            , currentDiagram = Just diagram
            , diagramModel = model_
        }
        (cmd_ |> Cmd.map UpdateDiagram)
        |> Return.andThen stopProgress


changeRouteInit : Model -> Return Msg Model
changeRouteInit model =
    Return.return model (Task.perform Init Dom.getViewport)


initListPage : Model -> Return Msg Model
initListPage model =
    let
        ( model_, cmd_ ) =
            DiagramList.init model.session model.lang model.diagramListModel.apiRoot model.isOnline
    in
    Return.return { model | diagramListModel = model_ } (cmd_ |> Cmd.map UpdateDiagramList)


initSettingsPage : Model -> Return Msg Model
initSettingsPage model =
    let
        ( model_, cmd_ ) =
            SettingsPage.init model.session model.settingsModel.settings
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
                , title = model.title
                }
    in
    Return.return { model | shareModel = shareModel } (cmd_ |> Cmd.map UpdateShare)


loadShareItem : ShareToken -> Model -> Return Msg Model
loadShareItem token model =
    Return.return model
        (Task.attempt Load <|
            Request.shareItem
                (Session.getIdToken model.session)
                (ShareToken.toString token)
                Nothing
        )


loadWithPasswordShareItem : ShareToken -> Maybe String -> Model -> Return Msg Model
loadWithPasswordShareItem token password model =
    Return.return model
        (Task.attempt LoadWithPassword <|
            Request.shareItem
                (Session.getIdToken model.session)
                (ShareToken.toString token)
                password
        )


loadItem : DiagramId -> Model -> Return Msg Model
loadItem id_ model =
    let
        loadFromRemote =
            Return.return model
                (Task.attempt Load <|
                    Request.item
                        (Session.getIdToken model.session)
                        (DiagramId.toString id_)
                )
    in
    case model.session of
        Session.SignedIn user ->
            case user.loginProvider of
                LoginProvider.Github (Just accessToken) ->
                    if DiagramId.isGithubId id_ then
                        Return.return model
                            (Task.attempt Load <|
                                Request.gistItem
                                    (Session.getIdToken model.session)
                                    accessToken
                                    (DiagramId.toString id_)
                            )

                    else
                        loadFromRemote

                LoginProvider.Github Nothing ->
                    if DiagramId.isGithubId id_ then
                        Return.return model <| Ports.getGithubAccessToken (DiagramId.toString id_)

                    else
                        loadFromRemote

                _ ->
                    loadFromRemote

        Session.Guest ->
            Return.singleton model


loadPublicItem : DiagramId -> Model -> Return Msg Model
loadPublicItem id_ model =
    Return.return model
        (Task.attempt Load <|
            Request.publicItem
                (Session.getIdToken model.session)
                (DiagramId.toString id_)
        )


loadRemoteSettings : Diagram -> Model -> Return Msg Model
loadRemoteSettings diagram model =
    Return.return model
        (Task.attempt LoadSettings <|
            Request.settings
                (Session.getIdToken model.session)
                diagram
        )


loadSettings : Model -> Return Msg Model
loadSettings model =
    case ( Session.isSignedIn model.session, model.currentDiagram ) of
        ( True, Just d ) ->
            loadRemoteSettings d.diagram model

        _ ->
            Return.singleton model


saveSettings : Model -> Return Msg Model
saveSettings model =
    case ( Route.toRoute model.url, Session.isSignedIn model.session, model.currentDiagram ) of
        ( Route.Settings, True, Just d ) ->
            saveSettingsToRemote d.diagram model.settingsModel.settings.storyMap model

        _ ->
            Return.singleton model


setSettings : DiagramModel.Settings -> Model -> Return Msg Model
setSettings settings model =
    let
        newSettings =
            model.settingsModel
    in
    Return.singleton
        { model
            | diagramModel = model.diagramModel |> DiagramModel.ofSettings.set settings
            , settingsModel = { newSettings | settings = model.settingsModel.settings |> Settings.storyMapOfSettings.set settings }
        }


saveSettingsToRemote : Diagram -> DiagramModel.Settings -> Model -> Return Msg Model
saveSettingsToRemote diagram settings model =
    Return.return model
        (Task.attempt SaveSettings <|
            Request.saveSettings
                (Session.getIdToken model.session)
                diagram
                { font = settings.font
                , width = settings.size.width
                , height = settings.size.height
                , backgroundColor = settings.backgroundColor
                , activityColor =
                    { foregroundColor = settings.color.activity.color
                    , backgroundColor = settings.color.activity.backgroundColor
                    }
                , taskColor =
                    { foregroundColor = settings.color.task.color
                    , backgroundColor = settings.color.task.backgroundColor
                    }
                , storyColor =
                    { foregroundColor = settings.color.story.color
                    , backgroundColor = settings.color.story.backgroundColor
                    }
                , lineColor = settings.color.line
                , labelColor = settings.color.label
                , textColor =
                    case settings.color.text of
                        Just c ->
                            OptionalArgument.Present c

                        Nothing ->
                            OptionalArgument.Absent
                , zoomControl =
                    case settings.zoomControl of
                        Just z ->
                            OptionalArgument.Present z

                        Nothing ->
                            OptionalArgument.Absent
                , scale =
                    case settings.scale of
                        Just s ->
                            OptionalArgument.Present s

                        Nothing ->
                            OptionalArgument.Absent
                }
        )


revokeGistToken : Model -> Return Msg Model
revokeGistToken model =
    case model.session of
        Session.SignedIn user ->
            case user.loginProvider of
                LoginProvider.Github (Just accessToken) ->
                    Return.return model
                        (Task.attempt CallApi
                            (TokenApi.revokeGistToken
                                (Session.getIdToken model.session)
                                accessToken
                                |> Task.mapError (\_ -> Message.messageFailedRevokeToken)
                            )
                        )

                _ ->
                    Return.singleton model

        Session.Guest ->
            Return.singleton model


startProgress : Model -> Return Msg Model
startProgress model =
    Return.singleton { model | progress = True }


stopProgress : Model -> Return Msg Model
stopProgress model =
    Return.singleton { model | progress = False }


closeNotification : Return.ReturnF Msg Model
closeNotification =
    Return.command (Utils.delay 3000 HandleCloseNotification)


showWarningMessage : Message -> Model -> Return Msg Model
showWarningMessage msg model =
    Return.return model
        (Notification.showWarningNotifcation (msg model.lang)
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


showErrorMessage : Message -> Model -> Return Msg Model
showErrorMessage msg model =
    Return.return model
        (Notification.showErrorNotifcation (msg model.lang)
            |> ShowNotification
            |> Task.succeed
            |> Task.perform identity
        )
        |> closeNotification


openFullscreen : Return.ReturnF Msg Model
openFullscreen =
    Return.command <| Ports.openFullscreen ()


closeFullscreen : Return.ReturnF Msg Model
closeFullscreen =
    Return.command <| Ports.closeFullscreen ()


closeMenu : Model -> Return Msg Model
closeMenu model =
    Return.singleton { model | openMenu = Nothing }


saveDiagram : DiagramItem -> Return.ReturnF Msg Model
saveDiagram item =
    Return.command <| (Ports.saveDiagram <| DiagramItem.encoder item)


saveToLocal : DiagramItem -> Return.ReturnF Msg Model
saveToLocal item =
    Return.command <| (Ports.saveDiagram <| DiagramItem.encoder { item | isRemote = False })


changePublicState : DiagramItem -> Bool -> Model -> Return Msg Model
changePublicState diagram isPublic model =
    Return.return model <|
        Task.attempt ChangePublicStatusCompleted
            (Request.save
                (Session.getIdToken model.session)
                (DiagramItem.toInputItem diagram)
                isPublic
                |> Task.mapError (\_ -> diagram)
            )


saveToRemote : DiagramItem -> Model -> Return Msg Model
saveToRemote diagram model =
    case model.session of
        Session.SignedIn user ->
            case ( diagram.location, model.settingsModel.settings.location, user.loginProvider ) of
                ( Just DiagramLocation.Gist, _, LoginProvider.Github (Just accessToken) ) ->
                    let
                        saveTask =
                            Request.saveGist (Session.getIdToken model.session) accessToken (DiagramItem.toInputGistItem diagram) (Text.toString diagram.text)
                    in
                    Return.return model <| Task.attempt SaveToRemoteCompleted saveTask

                ( _, Just DiagramLocation.Gist, LoginProvider.Github (Just accessToken) ) ->
                    let
                        saveTask =
                            Request.saveGist (Session.getIdToken model.session) accessToken (DiagramItem.toInputGistItem diagram) (Text.toString diagram.text)
                    in
                    Return.return model <| Task.attempt SaveToRemoteCompleted saveTask

                _ ->
                    let
                        saveTask =
                            Request.save (Session.getIdToken model.session) (DiagramItem.toInputItem diagram) diagram.isPublic
                    in
                    Return.return model <| Task.attempt SaveToRemoteCompleted saveTask

        Session.Guest ->
            Return.singleton model


setFocus : String -> Model -> Return Msg Model
setFocus id model =
    Return.return model
        (Task.attempt (\_ -> NoOp)
            (Dom.focus id)
        )


setFocusEditor : Return.ReturnF Msg Model
setFocusEditor =
    Return.command <| Ports.focusEditor ()


pushUrl : String -> Model -> Return Msg Model
pushUrl url model =
    Return.return model <| Nav.pushUrl model.key url


updateIdToken : Model -> Return Msg Model
updateIdToken model =
    Return.return model <| Ports.refreshToken ()


switchPage : Page -> Model -> Return Msg Model
switchPage page model =
    Return.singleton { model | page = page }


hideZoomControl : Model -> Return Msg Model
hideZoomControl model =
    Return.singleton
        { model
            | diagramModel =
                model.diagramModel
                    |> DiagramModel.ofShowZoomControl.set False
        }


showZoomControl : Model -> Return Msg Model
showZoomControl model =
    Return.singleton
        { model
            | diagramModel =
                model.diagramModel
                    |> DiagramModel.ofShowZoomControl.set True
        }


fullscreenDiagram : Model -> Return Msg Model
fullscreenDiagram model =
    Return.singleton
        { model
            | diagramModel =
                model.diagramModel
                    |> DiagramModel.ofFullscreen.set True
        }


setText : String -> Model -> Return Msg Model
setText text model =
    Return.singleton
        { model
            | diagramModel =
                model.diagramModel
                    |> DiagramModel.ofText.set (Text.edit model.diagramModel.text text)
        }


needSaved : Model -> Return Msg Model
needSaved model =
    Return.singleton
        { model
            | diagramModel =
                model.diagramModel
                    |> DiagramModel.ofText.set (Text.change model.diagramModel.text)
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
    Return.singleton { model | title = Title.fromString <| title }


untitled : Model -> Return Msg Model
untitled model =
    Return.singleton { model | title = Title.untitled }


startEditTitle : Model -> Return Msg Model
startEditTitle model =
    Return.return model <| Task.perform identity <| Task.succeed StartEditTitle


setCurrentDiagram : Maybe DiagramItem -> Model -> Return Msg Model
setCurrentDiagram currentDiagram model =
    Return.singleton { model | currentDiagram = currentDiagram }


setDiagramSettings : DiagramModel.Settings -> Model -> Return Msg Model
setDiagramSettings settings model =
    Return.singleton
        { model
            | diagramModel =
                model.diagramModel
                    |> DiagramModel.ofSettings.set settings
        }


setDiagramType : Diagram -> Model -> Return Msg Model
setDiagramType type_ model =
    Return.singleton
        { model
            | diagramModel =
                model.diagramModel
                    |> DiagramModel.ofDiagramType.set type_
        }


historyBack : Nav.Key -> Return.ReturnF Msg Model
historyBack key =
    Return.command <| Nav.back key 1


moveTo : Route -> Model -> Return Msg Model
moveTo route model =
    Return.return model <| Route.moveTo model.key route


redirectToLastEditedFile : Model -> Return Msg Model
redirectToLastEditedFile model =
    case ( Maybe.andThen .id model.currentDiagram, Maybe.map .diagram model.currentDiagram ) of
        ( Just id_, Just diagramType ) ->
            moveTo (Route.EditFile diagramType id_) model

        _ ->
            Return.singleton model


showConfirmDialog : String -> String -> Route -> Model -> Return Msg Model
showConfirmDialog title message route model =
    Return.singleton
        { model
            | confirmDialog = Show { title = title, message = message, ok = MoveTo route, cancel = CloseDialog }
        }


closeDialog : Model -> Return Msg Model
closeDialog model =
    Return.singleton { model | confirmDialog = Hide }
