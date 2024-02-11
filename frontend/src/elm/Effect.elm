module Effect exposing
    ( changePublicState
    , changeRouteInit
    , closeLocalFile
    , getGistTokenAfterSave
    , historyBack
    , revokeGistToken
    , setFocus
    , setFocusEditor
    , toggleFullscreen
    , updateIdToken
    )

import Api.Http.Token as TokenApi
import Api.Request as Request
import Browser.Dom as Dom exposing (Viewport)
import Browser.Navigation as Nav
import Diagram.Types.Item as DiagramItem exposing (DiagramItem)
import Message exposing (Message)
import Models.LoginProvider as LoginProvider
import Models.Session as Session exposing (Session)
import Models.Window as Window exposing (Window)
import Ports
import Return
import Task


changePublicState : (Result DiagramItem DiagramItem -> msg) -> { isPublic : Bool, item : DiagramItem, session : Session } -> Return.ReturnF msg model
changePublicState msg { isPublic, item, session } =
    Request.save
        (Session.getIdToken session)
        isPublic
        (DiagramItem.toInputItem item)
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
        Return.command <| Ports.closeFullscreen ()

    else
        Return.command <| Ports.openFullscreen ()


updateIdToken : Return.ReturnF msg model
updateIdToken =
    Return.command <| Ports.refreshToken ()
