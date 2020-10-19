port module Ports exposing (changeText, closeFullscreen, copyClipboard, decodeShareText, downloadCompleted, downloadHtml, downloadPdf, downloadPng, downloadSvg, encodeShareText, focusEditor, getDiagram, gotLocalDiagramJson, gotLocalDiagramsJson, insertTextLines, layoutEditor, loadEditor, loadText, selectLine, onAuthStateChanged, onDecodeShareText, onEncodeShareText, onErrorNotification, onNotification, onWarnNotification, openFullscreen, progress, reload, removeRemoteDiagram, saveDiagram, saveSettings, saveToLocalCompleted, saveToRemote, setEditorLanguage, shortcuts, signIn, signOut, startDownload)

import Data.Session exposing (User)
import Json.Decode as D
import Json.Encode as E
import Models.Model exposing (DownloadFileInfo, DownloadInfo, Msg(..), Notification(..), ShareInfo)
import Settings exposing (EditorSettings)


port changeText : (String -> msg) -> Sub msg


port progress : (Bool -> msg) -> Sub msg


port onAuthStateChanged : (Maybe User -> msg) -> Sub msg


port startDownload : (DownloadFileInfo -> msg) -> Sub msg


port onDecodeShareText : (String -> msg) -> Sub msg


port onEncodeShareText : (String -> msg) -> Sub msg


port onNotification : (String -> msg) -> Sub msg


port onErrorNotification : (String -> msg) -> Sub msg


port onWarnNotification : (String -> msg) -> Sub msg


port shortcuts : (String -> msg) -> Sub msg


port removeRemoteDiagram : (D.Value -> msg) -> Sub msg


port downloadPng : DownloadInfo -> Cmd msg


port downloadSvg : DownloadInfo -> Cmd msg


port downloadPdf : DownloadInfo -> Cmd msg


port downloadHtml : DownloadInfo -> Cmd msg


port loadEditor : ( String, EditorSettings ) -> Cmd msg


port signIn : String -> Cmd msg


port signOut : () -> Cmd msg


port focusEditor : () -> Cmd msg


port loadText : String -> Cmd msg


port layoutEditor : Int -> Cmd msg


port saveSettings : E.Value -> Cmd msg


port setEditorLanguage : String -> Cmd msg


port decodeShareText : String -> Cmd msg


port encodeShareText : ShareInfo -> Cmd msg


port copyClipboard : String -> Cmd msg


port downloadCompleted : (( Int, Int ) -> msg) -> Sub msg


port openFullscreen : () -> Cmd msg


port closeFullscreen : () -> Cmd msg


port saveDiagram : E.Value -> Cmd msg


port getDiagram : String -> Cmd msg


port gotLocalDiagramJson : (D.Value -> msg) -> Sub msg


port gotLocalDiagramsJson : (D.Value -> msg) -> Sub msg


port reload : (String -> msg) -> Sub msg


port saveToRemote : (D.Value -> msg) -> Sub msg


port saveToLocalCompleted : (D.Value -> msg) -> Sub msg


port insertTextLines : List String -> Cmd msg


port selectLine: Int -> Cmd msg
