module Action exposing
    ( changePublicState
    , changeRouteInit
    , closeLocalFile
    , historyBack
    , loadItem
    , loadLocalDiagram
    , loadPublicItem
    , loadSettings
    , loadShareItem
    , loadText
    , loadWithPasswordShareItem
    , revokeGistToken
    , saveDiagram
    , saveLocalFile
    , saveSettings
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
import Models.DiagramId as DiagramId exposing (DiagramId)
import Models.DiagramItem as DiagramItem exposing (DiagramItem)
import Models.DiagramLocation as DiagramLocation
import Models.DiagramSettings as DiagramSettings
import Models.DiagramType as DiagramType exposing (DiagramType)
import Models.Dialog exposing (ConfirmDialog(..))
import Models.LoginProvider as LoginProvider
import Models.Session as Session exposing (Session)
import Models.SettingsCache as SettingCache exposing (SettingsCache)
import Models.ShareToken as ShareToken exposing (ShareToken)
import Models.Text as Text
import Models.Title as Title
import Models.Window as Window exposing (Window)
import Ports
import Return exposing (Return)
import Route
import Settings
import Task
import Url


changePublicState : (Result DiagramItem DiagramItem -> msg) -> { item : DiagramItem, isPublic : Bool, session : Session } -> Return.ReturnF msg model
changePublicState msg { item, isPublic, session } =
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
loadItem msg { session, id } =
    case session of
        Session.SignedIn user ->
            case user.loginProvider of
                LoginProvider.Github (Just accessToken) ->
                    if DiagramId.isGithubId id then
                        Request.gistItem
                            (Session.getIdToken session)
                            accessToken
                            (DiagramId.toString id)
                            |> Task.attempt msg
                            |> Return.command

                    else
                        loadFromRemote msg { session = session, id = id }

                LoginProvider.Github Nothing ->
                    if DiagramId.isGithubId id then
                        Return.command <| Ports.getGithubAccessToken (DiagramId.toString id)

                    else
                        loadFromRemote msg { session = session, id = id }

                _ ->
                    loadFromRemote msg { session = session, id = id }

        Session.Guest ->
            Return.zero


loadLocalDiagram : DiagramId -> Return.ReturnF msg model
loadLocalDiagram diagramId =
    Return.command <| Ports.getDiagram (DiagramId.toString diagramId)


loadPublicItem : (Result RequestError DiagramItem -> msg) -> { id : DiagramId, session : Session } -> Return.ReturnF msg model
loadPublicItem msg { id, session } =
    Request.publicItem
        (Session.getIdToken session)
        (DiagramId.toString id)
        |> Task.attempt msg
        |> Return.command


loadSettings : (Result RequestError DiagramSettings.Settings -> msg) -> { diagramType : DiagramType, cache : SettingsCache, session : Session } -> Return.ReturnF msg model
loadSettings msg { diagramType, cache, session } =
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
        Return.zero


loadShareItem : (Result RequestError DiagramItem -> msg) -> { token : ShareToken, session : Session } -> Return.ReturnF msg model
loadShareItem msg { token, session } =
    Request.shareItem
        (Session.getIdToken session)
        (ShareToken.toString token)
        Nothing
        |> Task.attempt msg
        |> Return.command


loadText : (Result RequestError DiagramItem -> msg) -> DiagramItem -> Return.ReturnF msg model
loadText msg diagram =
    Task.succeed diagram
        |> Task.attempt msg
        |> Return.command


loadWithPasswordShareItem : (Result RequestError DiagramItem -> msg) -> { token : ShareToken, password : Maybe String, session : Session } -> Return.ReturnF msg model
loadWithPasswordShareItem msg { token, password, session } =
    Request.shareItem
        (Session.getIdToken session)
        (ShareToken.toString token)
        password
        |> Task.attempt msg
        |> Return.command


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


saveDiagram : DiagramItem -> Return.ReturnF msg model
saveDiagram item =
    Return.command <| (Ports.saveDiagram <| DiagramItem.encoder item)


saveLocalFile : DiagramItem -> Return.ReturnF msg model
saveLocalFile item =
    let
        d : DiagramItem
        d =
            { item
                | title =
                    if String.endsWith ext <| "." ++ Title.toString item.title then
                        Title.fromString <| Title.toString item.title

                    else
                        Title.fromString <| Title.toString item.title ++ "." ++ DiagramType.toString item.diagram
            }

        ext : String
        ext =
            DiagramType.toString item.diagram
    in
    Return.command <| (Ports.saveLocalFile <| DiagramItem.encoder d)


saveSettings : (Result RequestError DiagramSettings.Settings -> msg) -> { session : Session, diagramType : DiagramType, url : Url.Url, settings : DiagramSettings.Settings } -> Return.ReturnF msg model
saveSettings msg { session, diagramType, url, settings } =
    case ( Route.toRoute url, Session.isSignedIn session ) of
        ( Route.Settings, True ) ->
            saveSettingsToRemote msg { diagramType = diagramType, settings = settings, session = session }

        _ ->
            Return.zero


saveToLocal : DiagramItem -> Return.ReturnF msg model
saveToLocal item =
    Return.command <| (Ports.saveDiagram <| DiagramItem.encoder { item | isRemote = False })


saveToRemote : (Result RequestError DiagramItem -> msg) -> { diagram : DiagramItem, session : Session, settings : Settings.Settings } -> Return.ReturnF msg model
saveToRemote msg { diagram, session, settings } =
    case session of
        Session.SignedIn user ->
            case ( diagram.location, settings.location, user.loginProvider ) of
                ( Just DiagramLocation.Gist, _, LoginProvider.Github (Just accessToken) ) ->
                    let
                        saveTask : Task.Task RequestError DiagramItem
                        saveTask =
                            Request.saveGist (Session.getIdToken session) accessToken (DiagramItem.toInputGistItem diagram) (Text.toString diagram.text)
                    in
                    Return.command <| Task.attempt msg saveTask

                ( _, Just DiagramLocation.Gist, LoginProvider.Github (Just accessToken) ) ->
                    let
                        saveTask : Task.Task RequestError DiagramItem
                        saveTask =
                            Request.saveGist (Session.getIdToken session) accessToken (DiagramItem.toInputGistItem diagram) (Text.toString diagram.text)
                    in
                    Return.command <| Task.attempt msg saveTask

                _ ->
                    let
                        saveTask : Task.Task RequestError DiagramItem
                        saveTask =
                            Request.save (Session.getIdToken session) (DiagramItem.toInputItem diagram) diagram.isPublic
                    in
                    Return.command <| Task.attempt msg saveTask

        Session.Guest ->
            Return.zero


setFocus : msg -> String -> Return.ReturnF msg model
setFocus msg id =
    Task.attempt (\_ -> msg)
        (Dom.focus id)
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


saveSettingsToRemote : (Result RequestError DiagramSettings.Settings -> msg) -> { session : Session, diagramType : DiagramType, settings : DiagramSettings.Settings } -> Return.ReturnF msg model
saveSettingsToRemote msg { session, diagramType, settings } =
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
