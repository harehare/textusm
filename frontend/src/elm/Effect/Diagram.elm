module Effect.Diagram exposing
    ( closeLocalFile
    , load
    , loadFromLocal
    , loadFromLocalForCopy
    , loadFromPublic
    , loadFromShare
    , loadFromShareWithoutPassword
    , loadSettings
    , save
    , saveDiagramSettings
    , saveSettingsToLocal
    , saveToLocal
    , saveToLocalFileSystem
    , saveToRemote
    )

import Api.Request as Request
import Api.RequestError exposing (RequestError)
import Graphql.OptionalArgument as OptionalArgument
import Models.Diagram.Id as DiagramId exposing (DiagramId)
import Models.Diagram.Item as DiagramItem exposing (DiagramItem)
import Models.Diagram.Location as DiagramLocation
import Models.Diagram.Settings as DiagramSettings
import Models.Diagram.Type as DiagramType exposing (DiagramType)
import Models.LoginProvider as LoginProvider
import Models.Session as Session exposing (Session)
import Models.Settings as Settings
import Models.SettingsCache as SettingCache exposing (SettingsCache)
import Models.ShareToken as ShareToken exposing (ShareToken)
import Models.Text as Text
import Models.Title as Title
import Ports
import Return
import Task


closeLocalFile : Return.ReturnF msg model
closeLocalFile =
    Return.command <| Ports.closeLocalFile ()


loadFromLocal : DiagramId -> Return.ReturnF msg model
loadFromLocal diagramId =
    DiagramId.toString diagramId
        |> Ports.getDiagram
        |> Return.command


loadFromLocalForCopy : DiagramId -> Return.ReturnF msg model
loadFromLocalForCopy diagramId =
    DiagramId.toString diagramId
        |> Ports.getDiagramForCopy
        |> Return.command


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


load : (Result RequestError DiagramItem -> msg) -> { id : DiagramId, session : Session } -> Return.ReturnF msg model
load msg { id, session } =
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


loadFromPublic : (Result RequestError DiagramItem -> msg) -> { id : DiagramId, session : Session } -> Return.ReturnF msg model
loadFromPublic msg { id, session } =
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
                Request.settings
                    (Session.getIdToken session)
                    diagramType
                    |> Task.attempt msg
                    |> Return.command

    else
        DiagramType.toString diagramType
            |> Ports.loadSettingsFromLocal
            |> Return.command


loadFromShare :
    (Result RequestError DiagramItem -> msg)
    ->
        { password : Maybe String
        , session : Session
        , token : ShareToken
        }
    -> Return.ReturnF msg model
loadFromShare msg { password, session, token } =
    Request.shareItem
        (Session.getIdToken session)
        (ShareToken.toString token)
        password
        |> Task.attempt msg
        |> Return.command


loadFromShareWithoutPassword : (Result RequestError DiagramItem -> msg) -> { session : Session, token : ShareToken } -> Return.ReturnF msg model
loadFromShareWithoutPassword msg { session, token } =
    loadFromShare msg { session = session, token = token, password = Nothing }


saveSettingsToLocal : Settings.Settings -> Return.ReturnF msg model
saveSettingsToLocal settings =
    Settings.encoder settings |> Ports.saveSettingsToLocal |> Return.command


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
        Request.saveSettings
            (Session.getIdToken session)
            diagramType
            { font = settings.diagramSettings.font
            , width = settings.diagramSettings.size.width
            , height = settings.diagramSettings.size.height
            , backgroundColor = settings.diagramSettings.backgroundColor
            , activityColor =
                { foregroundColor = settings.diagramSettings.color.activity.color
                , backgroundColor = settings.diagramSettings.color.activity.backgroundColor
                }
            , taskColor =
                { foregroundColor = settings.diagramSettings.color.task.color
                , backgroundColor = settings.diagramSettings.color.task.backgroundColor
                }
            , storyColor =
                { foregroundColor = settings.diagramSettings.color.story.color
                , backgroundColor = settings.diagramSettings.color.story.backgroundColor
                }
            , lineColor = settings.diagramSettings.color.line
            , labelColor = settings.diagramSettings.color.label
            , textColor =
                case settings.diagramSettings.color.text of
                    Just c ->
                        OptionalArgument.Present c

                    Nothing ->
                        OptionalArgument.Absent
            , zoomControl =
                case settings.diagramSettings.zoomControl of
                    Just z ->
                        OptionalArgument.Present z

                    Nothing ->
                        OptionalArgument.Absent
            , scale =
                case settings.diagramSettings.scale of
                    Just s ->
                        OptionalArgument.Present s

                    Nothing ->
                        OptionalArgument.Absent
            , toolbar =
                case settings.diagramSettings.toolbar of
                    Just z ->
                        OptionalArgument.Present z

                    Nothing ->
                        OptionalArgument.Absent
            }
            |> Task.attempt msg
            |> Return.command

    else
        saveSettingsToLocal { settings | diagram = Maybe.map (\d -> { d | diagram = diagramType }) settings.diagram }


saveToLocalFileSystem : DiagramItem -> Return.ReturnF msg model
saveToLocalFileSystem item =
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


saveToLocal : DiagramItem -> Return.ReturnF msg model
saveToLocal item =
    DiagramItem.encoder { item | location = Just DiagramLocation.Local }
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
                    Request.save (Session.getIdToken session) diagram.isPublic (DiagramItem.toInputItem diagram)
            )
                |> Task.attempt msg
                |> Return.command

        Session.Guest ->
            Return.zero


save : DiagramItem -> Return.ReturnF msg model
save item =
    DiagramItem.encoder item
        |> Ports.saveDiagram
        |> Return.command
