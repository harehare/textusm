port module Subscriptions exposing (applySettings, changeText, closeFullscreen, copyClipboard, decodeShareText, downloadCompleted, downloadHtml, downloadPdf, downloadPng, downloadSvg, editSettings, encodeShareText, errorLine, getDiagram, getDiagrams, layoutEditor, loadEditor, loadText, login, logout, openFullscreen, removeDiagrams, saveDiagram, saveSettings, selectLine, selectTextById, setEditorLanguage, subscriptions)

import Browser.Events exposing (onMouseMove, onMouseUp, onResize, onVisibilityChange)
import Json.Decode as D
import Models.Diagram as DiagramModel
import Models.DiagramItem exposing (DiagramItem)
import Models.DiagramList as DiagramListModel
import Models.Model exposing (DownloadFileInfo, DownloadInfo, EditorSettings, Model, Msg(..), Notification(..), Settings, ShareInfo)
import Models.User exposing (User)


port changeText : (String -> msg) -> Sub msg


port progress : (Bool -> msg) -> Sub msg


port onAuthStateChanged : (Maybe User -> msg) -> Sub msg


port startDownload : (DownloadFileInfo -> msg) -> Sub msg


port applySettings : (Settings -> msg) -> Sub msg


port onDecodeShareText : (String -> msg) -> Sub msg


port onEncodeShareText : (String -> msg) -> Sub msg


port onNotification : (String -> msg) -> Sub msg


port onErrorNotification : (String -> msg) -> Sub msg


port onWarnNotification : (String -> msg) -> Sub msg


port shortcuts : (String -> msg) -> Sub msg


port removeRemoteDiagram : (DiagramItem -> msg) -> Sub msg


port downloadPng : DownloadInfo -> Cmd msg


port downloadSvg : DownloadInfo -> Cmd msg


port downloadPdf : DownloadInfo -> Cmd msg


port downloadHtml : DownloadInfo -> Cmd msg


port loadEditor : ( String, EditorSettings ) -> Cmd msg


port login : () -> Cmd msg


port logout : () -> Cmd msg


port loadText : String -> Cmd msg


port layoutEditor : Int -> Cmd msg


port saveSettings : Settings -> Cmd msg


port selectLine : Int -> Cmd msg


port setEditorLanguage : String -> Cmd msg


port errorLine : String -> Cmd msg


port editSettings : Settings -> Cmd msg


port decodeShareText : String -> Cmd msg


port encodeShareText : ShareInfo -> Cmd msg


port copyClipboard : String -> Cmd msg


port selectTextById : String -> Cmd msg


port downloadCompleted : (( Int, Int ) -> msg) -> Sub msg


port openFullscreen : () -> Cmd msg


port closeFullscreen : () -> Cmd msg


port saveDiagram : DiagramItem -> Cmd msg


port removeDiagrams : DiagramItem -> Cmd msg


port getDiagrams : () -> Cmd msg


port getDiagram : String -> Cmd msg


port gotLocalDiagrams : (List DiagramItem -> msg) -> Sub msg


port removedDiagram : (( DiagramItem, Bool ) -> msg) -> Sub msg


port saveToRemote : (DiagramItem -> msg) -> Sub msg


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        ([ changeText (\text -> UpdateDiagram (DiagramModel.OnChangeText text))
         , applySettings ApplySettings
         , startDownload StartDownload
         , gotLocalDiagrams (\items -> UpdateDiagramList (DiagramListModel.GotLocalDiagrams items))
         , removedDiagram (\_ -> UpdateDiagramList DiagramListModel.Reload)
         , onVisibilityChange OnVisibilityChange
         , onResize (\width height -> UpdateDiagram (DiagramModel.OnResize width height))
         , onMouseUp (D.succeed (UpdateDiagram DiagramModel.Stop))
         , onEncodeShareText OnEncodeShareText
         , onDecodeShareText OnDecodeShareText
         , shortcuts Shortcuts
         , onNotification (\n -> OnAutoCloseNotification (Info n))
         , onErrorNotification (\n -> OnAutoCloseNotification (Error n))
         , onWarnNotification (\n -> OnAutoCloseNotification (Warning n))
         , onAuthStateChanged OnAuthStateChanged
         , saveToRemote SaveToRemote
         , removeRemoteDiagram (\diagram -> UpdateDiagramList <| DiagramListModel.RemoveRemote diagram)
         , downloadCompleted DownloadCompleted
         , progress Progress
         ]
            ++ (if model.window.moveStart then
                    [ onMouseUp (D.succeed Stop)
                    , onMouseMove (D.map OnWindowResize pageX)
                    ]

                else
                    [ Sub.none ]
               )
        )


pageX : D.Decoder Int
pageX =
    D.field "pageX" D.int
