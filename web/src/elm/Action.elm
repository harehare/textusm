module Action exposing (..)

import Browser.Dom as Dom
import Browser.Navigation as Nav
import Data.DiagramItem as DiagramItem exposing (DiagramItem)
import Data.Session as Session
import Data.Text as Text
import Data.Title as Title
import GraphQL.Request as Request
import Models.Diagram as DiagramModel
import Models.Model exposing (Model, Msg(..), Notification(..), Page, SwitchWindow(..))
import Ports
import RemoteData exposing (RemoteData(..))
import Return as Return exposing (Return)
import Route exposing (Route(..))
import Settings exposing (EditorSettings)
import Task
import TextUSM.Enum.Diagram exposing (Diagram)
import Utils.Utils as Utils


loadText : DiagramItem.DiagramItem -> Model -> Return Msg Model
loadText diagram model =
    Return.return model (Task.attempt Load <| Task.succeed diagram)


loadTextToEditor : Model -> Return Msg Model
loadTextToEditor model =
    Return.return model (Ports.loadText <| Text.toString model.diagramModel.text)


loadEditor : ( String, EditorSettings ) -> Model -> Return Msg Model
loadEditor editorSettings model =
    Return.return model (Ports.loadEditor editorSettings)


changeRouteInit : Model -> Return Msg Model
changeRouteInit model =
    Return.return model (Task.perform Init Dom.getViewport)


startProgress : Model -> Return Msg Model
startProgress model =
    Return.singleton { model | progress = True }


stopProgress : Model -> Return Msg Model
stopProgress model =
    Return.singleton { model | progress = False }


closeNotification : Model -> Return Msg Model
closeNotification model =
    Return.return model (Utils.delay 3000 OnCloseNotification)


showWarningMessage : String -> Model -> Return Msg Model
showWarningMessage msg model =
    Return.return model (Task.perform identity (Task.succeed (OnNotification (Warning msg))))
        |> Return.andThen closeNotification


showInfoMessage : String -> Model -> Return Msg Model
showInfoMessage msg model =
    Return.return model (Task.perform identity (Task.succeed (OnNotification (Info msg))))
        |> Return.andThen closeNotification


showErrorMessage : String -> Model -> Return Msg Model
showErrorMessage msg model =
    Return.return model (Task.perform identity (Task.succeed (OnNotification (Error msg))))
        |> Return.andThen closeNotification


openFullscreen : Model -> Return Msg Model
openFullscreen model =
    Return.return model (Ports.openFullscreen ())


closeFullscreen : Model -> Return Msg Model
closeFullscreen model =
    Return.return model (Ports.closeFullscreen ())


closeMenu : Model -> Return Msg Model
closeMenu model =
    Return.singleton { model | openMenu = Nothing }


saveDiagram : DiagramItem -> Model -> Return Msg Model
saveDiagram item model =
    Return.return model (Ports.saveDiagram <| DiagramItem.encoder item)


saveToLocal : DiagramItem -> Model -> Return Msg Model
saveToLocal item model =
    Return.return model (Ports.saveDiagram <| DiagramItem.encoder { item | isRemote = False })


saveToRemote : DiagramItem -> Model -> Return Msg Model
saveToRemote diagram model =
    let
        saveTask =
            Request.save { url = model.apiRoot, idToken = Session.getIdToken model.session } (DiagramItem.toInputItem diagram) diagram.isPublic
                |> Task.mapError (\_ -> diagram)
    in
    Return.return model (Task.attempt SaveToRemoteCompleted saveTask)


setFocus : String -> Model -> Return Msg Model
setFocus id model =
    Return.return model
        (Task.attempt (\_ -> NoOp)
            (Dom.focus id)
        )


pushUrl : String -> Model -> Return Msg Model
pushUrl url model =
    Return.return model (Nav.pushUrl model.key url)


updateIdToken : Model -> Return Msg Model
updateIdToken model =
    Return.return model (Ports.refreshToken ())


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


setTitle : String -> Model -> Return Msg Model
setTitle title model =
    Return.singleton { model | title = Title.fromString <| title }


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
