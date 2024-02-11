module Diagram.Effect exposing
    ( load
    , loadFromLocal
    , loadFromLocalForCopy
    , loadFromPublic
    , loadFromShare
    , loadFromShareWithoutPassword
    , save
    , saveToLocal
    , saveToLocalFileSystem
    , saveToRemote
    )

import Api.Request as Request
import Api.RequestError exposing (RequestError)
import Diagram.Types.Id as DiagramId exposing (DiagramId)
import Diagram.Types.Item as DiagramItem exposing (DiagramItem)
import Diagram.Types.Location as DiagramLocation
import Diagram.Types.Type as DiagramType
import Ports
import Return
import Task
import Types.LoginProvider as LoginProvider
import Types.Session as Session exposing (Session)
import Types.Settings as Settings
import Types.ShareToken as ShareToken exposing (ShareToken)
import Types.Text as Text
import Types.Title as Title


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
