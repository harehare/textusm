module Effect exposing
    ( changePublicState
    , changeRouteInit
    , closeLocalFile
    , getGistTokenAfterSave
    , historyBack
    , loadItem
    , loadLocalDiagram
    , loadPublicItem
    , loadSettings
    , loadShareItem
    , loadShareItemWithoutPassword
    , loadText
    , revokeGistToken
    , saveDiagram
    , saveDiagramSettings
    , saveLocalFile
    , saveSettingsToLocal
    , saveToLocal
    , saveToRemote
    , setFocus
    , setFocusEditor
    , toggleFullscreen
    , updateIdToken
    )

import Api.Http.Token as TokenApi
import Api.Request as Request
import Api.RequestError exposing (RequestError)
import Browser.Dom as Dom exposing (Viewport)
import Browser.Navigation as Nav
import Graphql.OptionalArgument as OptionalArgument
import Message exposing (Message)
import Models.Diagram.Id as DiagramId exposing (DiagramId)
import Models.Diagram.Item as DiagramItem exposing (DiagramItem)
import Models.Diagram.Location as DiagramLocation
import Models.Diagram.Settings as DiagramSettings
import Models.Diagram.Type as DiagramType exposing (DiagramType)
import Models.LoginProvider as LoginProvider
import Models.Session as Session exposing (Session)
import Models.SettingsCache as SettingCache exposing (SettingsCache)
import Models.ShareToken as ShareToken exposing (ShareToken)
import Models.Text as Text
import Models.Title as Title
import Models.Window as Window exposing (Window)
import Ports
import Return exposing (Return)
import Settings
import Task


changePublicState : (Result DiagramItem DiagramItem -> msg) -> { isPublic : Bool, item : DiagramItem, session : Session } -> Return.ReturnF msg model
changePublicState msg { isPublic, item, session } =
    Request.save
        (Session.getIdToken session)
        (DiagramItem.toInputItem item)
        isPublic
        |> Task.mapError (\_ -> item)
        |> Task.attempt msg
        |> Return.command


changeRouteInit : (Viewport -> msg) -> Return.ReturnF msg model
changeRouteInit msg =
    Return.command <| Task.perform msg Dom.getViewport


closeLocalFile : Return.ReturnF msg model
closeLocalFile =
    Return.command <| Ports.closeLocalFile ()


historyBack : Nav.Key -> Return.ReturnF msg model
historyBack key =
    Return.command <| Nav.back key 1


loadFromRemote :
    (Result RequestError DiagramItem -> msg)
    -> { id : DiagramId, session : Session }
    -> Return.ReturnF msg model
loadFromRemote msg { id, session } =
    Request.item
        (Session.getIdToken session)
        (DiagramId.toString id)
        |> Task.attempt msg
        |> Return.command


loadItem : (Result RequestError DiagramItem -> msg) -> { id : DiagramId, session : Session } -> Return.ReturnF msg model
loadItem msg { id, session } =
    case session of
        Session.SignedIn user ->
            case user.loginProvider of
                LoginProvider.Github (Just accessToken) ->
                    if DiagramId.isGithubId id then
                        Request.gistItem (Session.getIdToken session) accessToken id
                            |> Task.attempt msg
                            |> Return.command

                    else
                        loadFromRemote msg { id = id, session = session }

                LoginProvider.Github Nothing ->
                    if DiagramId.isGithubId id then
                        Return.command <| Ports.getGithubAccessToken (DiagramId.toString id)

                    else
                        loadFromRemote msg { id = id, session = session }

                _ ->
                    loadFromRemote msg { id = id, session = session }

        Session.Guest ->
            Return.zero


loadLocalDiagram : DiagramId -> Return.ReturnF msg model
loadLocalDiagram diagramId =
    DiagramId.toString diagramId
        |> Ports.getDiagram
        |> Return.command


loadPublicItem : (Result RequestError DiagramItem -> msg) -> { id : DiagramId, session : Session } -> Return.ReturnF msg model
loadPublicItem msg { id, session } =
    Request.publicItem
        (Session.getIdToken session)
        (DiagramId.toString id)
        |> Task.attempt msg
        |> Return.command


loadSettings :
    (Result RequestError DiagramSettings.Settings -> msg)
    ->
        { cache : SettingsCache
        , diagramType : DiagramType
        , session : Session
        }
    -> Return.ReturnF msg model
loadSettings msg { cache, diagramType, session } =
    if Session.isSignedIn session then
        case SettingCache.get cache diagramType of
            Just setting ->
                Ok setting
                    |> msg
                    |> Task.succeed
                    |> Task.perform identity
                    |> Return.command

            Nothing ->
                loadRemoteSettings msg { diagramType = diagramType, session = session }

    else
        DiagramType.toString diagramType
            |> Ports.loadSettingsFromLocal
            |> Return.command


loadShareItem :
    (Result RequestError DiagramItem -> msg)
    ->
        { password : Maybe String
        , session : Session
        , token : ShareToken
        }
    -> Return.ReturnF msg model
loadShareItem msg { password, session, token } =
    Request.shareItem
        (Session.getIdToken session)
        (ShareToken.toString token)
        password
        |> Task.attempt msg
        |> Return.command


loadShareItemWithoutPassword : (Result RequestError DiagramItem -> msg) -> { session : Session, token : ShareToken } -> Return.ReturnF msg model
loadShareItemWithoutPassword msg { session, token } =
    loadShareItem msg { session = session, token = token, password = Nothing }


loadText : (Result RequestError DiagramItem -> msg) -> DiagramItem -> Return.ReturnF msg model
loadText msg diagram =
    Task.succeed diagram
        |> Task.attempt msg
        |> Return.command


getGistTokenAfterSave : Return.ReturnF msg model
getGistTokenAfterSave =
    Return.command <| Ports.getGithubAccessToken ""


revokeGistToken : (Result Message () -> msg) -> Session -> Return.ReturnF msg model
revokeGistToken msg session =
    case session of
        Session.SignedIn user ->
            case user.loginProvider of
                LoginProvider.Github (Just accessToken) ->
                    (TokenApi.revokeGistToken
                        (Session.getIdToken session)
                        accessToken
                        |> Task.mapError (\_ -> Message.messageFailedRevokeToken)
                    )
                        |> Task.attempt msg
                        |> Return.command

                _ ->
                    Return.zero

        Session.Guest ->
            Return.zero


saveLocalFile : DiagramItem -> Return.ReturnF msg model
saveLocalFile item =
    DiagramItem.encoder
        { item
            | title =
                if String.endsWith (DiagramType.toString item.diagram) <| "." ++ Title.toString item.title then
                    Title.fromString <| Title.toString item.title

                else
                    Title.fromString <| Title.toString item.title ++ "." ++ DiagramType.toString item.diagram
        }
        |> Ports.saveLocalFile
        |> Return.command


saveDiagramSettings :
    (Result RequestError DiagramSettings.Settings -> msg)
    ->
        { diagramType : DiagramType
        , session : Session
        , settings : Settings.Settings
        }
    -> Return.ReturnF msg model
saveDiagramSettings msg { diagramType, session, settings } =
    if Session.isSignedIn session then
        saveSettingsToRemote msg { diagramType = diagramType, session = session, settings = settings.storyMap }

    else
        saveSettingsToLocal { settings | diagram = Maybe.map (\d -> { d | diagram = diagramType }) settings.diagram }


saveSettingsToLocal : Settings.Settings -> Return.ReturnF msg model
saveSettingsToLocal settings =
    Settings.settingsEncoder settings |> Ports.saveSettingsToLocal |> Return.command


saveToLocal : DiagramItem -> Return.ReturnF msg model
saveToLocal item =
    DiagramItem.encoder { item | location = Just DiagramLocation.Local }
        |> Ports.saveDiagram
        |> Return.command


saveDiagram : DiagramItem -> Return.ReturnF msg model
saveDiagram item =
    DiagramItem.encoder item
        |> Ports.saveDiagram
        |> Return.command


saveToRemote : (Result RequestError DiagramItem -> msg) -> { diagram : DiagramItem, session : Session, settings : Settings.Settings } -> Return.ReturnF msg model
saveToRemote msg { diagram, session, settings } =
    case session of
        Session.SignedIn user ->
            (case ( diagram.location, settings.location, user.loginProvider ) of
                ( Just DiagramLocation.Gist, _, LoginProvider.Github (Just accessToken) ) ->
                    Request.saveGist (Session.getIdToken session) accessToken (DiagramItem.toInputGistItem diagram) (Text.toString diagram.text)

                ( _, Just DiagramLocation.Gist, LoginProvider.Github (Just accessToken) ) ->
                    Request.saveGist (Session.getIdToken session) accessToken (DiagramItem.toInputGistItem diagram) (Text.toString diagram.text)

                _ ->
                    Request.save (Session.getIdToken session) (DiagramItem.toInputItem diagram) diagram.isPublic
            )
                |> Task.attempt msg
                |> Return.command

        Session.Guest ->
            Return.zero


setFocus : msg -> String -> Return.ReturnF msg model
setFocus msg id =
    Dom.focus id
        |> Task.attempt (\_ -> msg)
        |> Return.command


setFocusEditor : Return.ReturnF msg model
setFocusEditor =
    Return.command <| Ports.focusEditor ()


toggleFullscreen : Window -> Return.ReturnF msg model
toggleFullscreen window =
    if Window.isFullscreen window then
        closeFullscreen

    else
        openFullscreen


updateIdToken : Return.ReturnF msg model
updateIdToken =
    Return.command <| Ports.refreshToken ()


loadRemoteSettings : (Result RequestError DiagramSettings.Settings -> msg) -> { diagramType : DiagramType, session : Session } -> Return msg model -> Return msg model
loadRemoteSettings msg { diagramType, session } =
    Request.settings
        (Session.getIdToken session)
        diagramType
        |> Task.attempt msg
        |> Return.command


openFullscreen : Return.ReturnF msg model
openFullscreen =
    Return.command <| Ports.openFullscreen ()


closeFullscreen : Return.ReturnF msg model
closeFullscreen =
    Return.command <| Ports.closeFullscreen ()


saveSettingsToRemote : (Result RequestError DiagramSettings.Settings -> msg) -> { diagramType : DiagramType, session : Session, settings : DiagramSettings.Settings } -> Return.ReturnF msg model
saveSettingsToRemote msg { diagramType, session, settings } =
    Request.saveSettings
        (Session.getIdToken session)
        diagramType
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
        , toolbar =
            case settings.toolbar of
                Just z ->
                    OptionalArgument.Present z

                Nothing ->
                    OptionalArgument.Absent
        }
        |> Task.attempt msg
        |> Return.command
