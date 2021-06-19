module Action exposing (..)

import Browser.Dom as Dom
import Browser.Navigation as Nav
import Data.DiagramId as DiagramId exposing (DiagramId)
import Data.DiagramItem as DiagramItem exposing (DiagramItem)
import Data.Session as Session exposing (Session)
import Data.Text as Text
import Data.Title as Title
import GraphQL.Request as Request
import Models.Diagram as DiagramModel
import Models.Dialog exposing (ConfirmDialog(..))
import Models.Model exposing (Model, Msg(..), Notification(..), SwitchWindow(..))
import Models.Page exposing (Page)
import Ports
import RemoteData exposing (RemoteData(..))
import Return as Return exposing (Return)
import Route exposing (Route(..))
import Task
import TextUSM.Enum.Diagram exposing (Diagram)
import Utils.Utils as Utils


loadText : DiagramItem.DiagramItem -> Model -> Return Msg Model
loadText diagram model =
    Return.return model (Task.attempt Load <| Task.succeed diagram)


loadLocalDiagram : DiagramId -> Model -> Return Msg Model
loadLocalDiagram diagramId model =
    Return.return model <| Ports.getDiagram (DiagramId.toString diagramId)


changeRouteInit : Model -> Return Msg Model
changeRouteInit model =
    Return.return model (Task.perform Init Dom.getViewport)


startProgress : Model -> Return Msg Model
startProgress model =
    Return.singleton { model | progress = True }


stopProgress : Model -> Return Msg Model
stopProgress model =
    Return.singleton { model | progress = False }


closeNotification : Return.ReturnF Msg Model
closeNotification =
    Return.command (Utils.delay 3000 HandleCloseNotification)


showWarningMessage : String -> Return.ReturnF Msg Model
showWarningMessage msg =
    Return.command (Task.perform identity <| Task.succeed <| ShowNotification <| Warning msg)
        >> closeNotification


showInfoMessage : String -> Model -> Return Msg Model
showInfoMessage msg model =
    Return.return model (Task.perform identity <| Task.succeed <| ShowNotification <| Info msg)
        |> closeNotification


showErrorMessage : String -> Return.ReturnF Msg Model
showErrorMessage msg =
    Return.command (Task.perform identity <| Task.succeed <| ShowNotification <| Error msg)
        >> closeNotification


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


saveToRemote : DiagramItem -> Session -> Return.ReturnF Msg Model
saveToRemote diagram session =
    let
        saveTask =
            Request.save (Session.getIdToken session) (DiagramItem.toInputItem diagram) diagram.isPublic
                |> Task.mapError (\_ -> diagram)
    in
    Return.command <| Task.attempt SaveToRemoteCompleted saveTask


setFocus : String -> Model -> Return Msg Model
setFocus id model =
    Return.return model
        (Task.attempt (\_ -> NoOp)
            (Dom.focus id)
        )


setFocusEditor : Return.ReturnF Msg Model
setFocusEditor =
    Return.command <| Ports.focusEditor ()


pushUrl : String -> Nav.Key -> Return.ReturnF Msg Model
pushUrl url key =
    Return.command <| Nav.pushUrl key url


updateIdToken : Return.ReturnF Msg Model
updateIdToken =
    Return.command <| Ports.refreshToken ()


switchPage : Page -> Model -> Return Msg Model
switchPage page model =
    Return.singleton { model | page = page }


hideZoomControl : Model -> Return Msg Model
hideZoomControl model =
    Return.singleton
        { model
            | diagramModel =
                model.diagramModel
                    |> DiagramModel.modelOfShowZoomControl.set False
        }


showZoomControl : Model -> Return Msg Model
showZoomControl model =
    Return.singleton
        { model
            | diagramModel =
                model.diagramModel
                    |> DiagramModel.modelOfShowZoomControl.set True
        }


fullscreenDiagram : Model -> Return Msg Model
fullscreenDiagram model =
    Return.singleton
        { model
            | diagramModel =
                model.diagramModel
                    |> DiagramModel.modelOfFullscreen.set True
        }


setText : String -> Model -> Return Msg Model
setText text model =
    Return.singleton
        { model
            | diagramModel =
                model.diagramModel
                    |> DiagramModel.modelOfText.set (Text.edit model.diagramModel.text text)
        }


needSaved : Model -> Return Msg Model
needSaved model =
    Return.singleton
        { model
            | diagramModel =
                model.diagramModel
                    |> DiagramModel.modelOfText.set (Text.change model.diagramModel.text)
        }


unchanged : Model -> Return Msg Model
unchanged model =
    Return.singleton
        { model
            | diagramModel =
                model.diagramModel
                    |> DiagramModel.modelOfText.set (Text.saved model.diagramModel.text)
        }


changed : Model -> Return Msg Model
changed model =
    Return.singleton
        { model
            | diagramModel =
                model.diagramModel
                    |> DiagramModel.modelOfText.set (Text.change model.diagramModel.text)
        }


setTitle : String -> Model -> Return Msg Model
setTitle title model =
    Return.singleton { model | title = Title.fromString <| title }


startEditTitle : Return.ReturnF Msg Model
startEditTitle =
    Return.command <| Task.perform identity <| Task.succeed StartEditTitle


setCurrentDiagram : Maybe DiagramItem -> Model -> Return Msg Model
setCurrentDiagram currentDiagram model =
    Return.singleton { model | currentDiagram = currentDiagram }


setDiagramSettings : DiagramModel.Settings -> Model -> Return Msg Model
setDiagramSettings settings model =
    Return.singleton
        { model
            | diagramModel =
                model.diagramModel
                    |> DiagramModel.modelOfSettings.set settings
        }


setDiagramType : Diagram -> Model -> Return Msg Model
setDiagramType type_ model =
    Return.singleton
        { model
            | diagramModel =
                model.diagramModel
                    |> DiagramModel.modelOfDiagramType.set type_
        }


historyBack : Nav.Key -> Return.ReturnF Msg Model
historyBack key =
    Return.command <| Nav.back key 1


moveTo : Nav.Key -> Route -> Return.ReturnF Msg Model
moveTo key route =
    Return.command <| Route.moveTo key route


redirectToLastEditedFile : Model -> Return.ReturnF Msg Model
redirectToLastEditedFile model =
    case ( Maybe.andThen .id model.currentDiagram, Maybe.map .diagram model.currentDiagram ) of
        ( Just id_, Just diagramType ) ->
            moveTo model.key <|
                Route.EditFile diagramType id_

        _ ->
            Return.zero


showConfirmDialog : String -> String -> Route -> Model -> Return Msg Model
showConfirmDialog title message route model =
    Return.singleton
        { model
            | confirmDialog = Show { title = title, message = message, ok = MoveTo route, cancel = CloseDialog }
        }


closeDialog : Model -> Return Msg Model
closeDialog model =
    Return.singleton { model | confirmDialog = Hide }
