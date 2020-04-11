port module Ports exposing (applySettings, changeText, closeFullscreen, copyClipboard, decodeShareText, downloadCompleted, downloadHtml, downloadPdf, downloadPng, downloadSvg, editSettings, encodeShareText, getDiagram, getDiagrams, gotLocalDiagramJson, layoutEditor, loadEditor, loadText, login, logout, onAuthStateChanged, onDecodeShareText, onEncodeShareText, onErrorNotification, onNotification, onWarnNotification, openFullscreen, progress, removeDiagrams, removeRemoteDiagram, removedDiagram, saveDiagram, saveSettings, saveToRemote, selectTextById, setEditorLanguage, shortcuts, startDownload)

import Json.Encode as E
import Models.Model exposing (DownloadFileInfo, DownloadInfo, Msg(..), Notification(..), ShareInfo)
import Models.Settings exposing (EditorSettings, Settings)
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


port removeRemoteDiagram : (String -> msg) -> Sub msg


port downloadPng : DownloadInfo -> Cmd msg


port downloadSvg : DownloadInfo -> Cmd msg


port downloadPdf : DownloadInfo -> Cmd msg


port downloadHtml : DownloadInfo -> Cmd msg


port loadEditor : ( String, EditorSettings ) -> Cmd msg


port login : String -> Cmd msg


port logout : () -> Cmd msg


port loadText : String -> Cmd msg


port layoutEditor : Int -> Cmd msg


port saveSettings : Settings -> Cmd msg


port setEditorLanguage : String -> Cmd msg


port editSettings : Settings -> Cmd msg


port decodeShareText : String -> Cmd msg


port encodeShareText : ShareInfo -> Cmd msg


port copyClipboard : String -> Cmd msg


port selectTextById : String -> Cmd msg


port downloadCompleted : (( Int, Int ) -> msg) -> Sub msg


port openFullscreen : () -> Cmd msg


port closeFullscreen : () -> Cmd msg


port saveDiagram : E.Value -> Cmd msg


port removeDiagrams : E.Value -> Cmd msg


port getDiagrams : () -> Cmd msg


port getDiagram : String -> Cmd msg


port gotLocalDiagramJson : (String -> msg) -> Sub msg


port removedDiagram : (( String, Bool ) -> msg) -> Sub msg


port saveToRemote : (String -> msg) -> Sub msg
