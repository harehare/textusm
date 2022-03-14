port module Ports exposing
    ( changeNetworkState
    , changeText
    , closeFullscreen
    , closeLocalFile
    , copyText
    , copyToClipboardPng
    , downloadCompleted
    , downloadHtml
    , downloadPdf
    , downloadPng
    , downloadSvg
    , focusEditor
    , fullscreen
    , getDiagram
    , getGithubAccessToken
    , gotGithubAccessToken
    , gotLocalDiagramJson
    , gotLocalDiagramsJson
    , insertText
    , notifyNewVersionAvailable
    , onAuthStateChanged
    , onNotification
    , onWarnNotification
    , openFullscreen
    , openLocalFile
    , openedLocalFile
    , progress
    , refreshToken
    , reload
    , removeRemoteDiagram
    , saveDiagram
    , saveLocalFile
    , saveSettings
    , saveToLocalCompleted
    , saveToRemote
    , savedLocalFile
    , sendErrorNotification
    , shortcuts
    , signIn
    , signOut
    , startDownload
    , updateIdToken
    )

import Json.Decode as D
import Json.Encode as E


type alias DownloadInfo =
    { width : Int
    , height : Int
    , id : String
    , title : String
    , text : String
    , x : Float
    , y : Float
    , diagramType : String
    }


port changeText : (String -> msg) -> Sub msg


port progress : (Bool -> msg) -> Sub msg


port onAuthStateChanged : (Maybe D.Value -> msg) -> Sub msg


port startDownload : ({ extension : String, mimeType : String, content : String } -> msg) -> Sub msg


port onNotification : (String -> msg) -> Sub msg


port sendErrorNotification : (String -> msg) -> Sub msg


port onWarnNotification : (String -> msg) -> Sub msg


port shortcuts : (String -> msg) -> Sub msg


port removeRemoteDiagram : (D.Value -> msg) -> Sub msg


port downloadPng : DownloadInfo -> Cmd msg


port copyToClipboardPng : DownloadInfo -> Cmd msg


port downloadSvg : DownloadInfo -> Cmd msg


port downloadPdf : DownloadInfo -> Cmd msg


port downloadHtml : DownloadInfo -> Cmd msg


port signIn : String -> Cmd msg


port signOut : () -> Cmd msg


port focusEditor : () -> Cmd msg


port saveSettings : E.Value -> Cmd msg


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


port fullscreen : (Bool -> msg) -> Sub msg


port refreshToken : () -> Cmd msg


port updateIdToken : (String -> msg) -> Sub msg


port getGithubAccessToken : String -> Cmd msg


port gotGithubAccessToken : ({ cmd : String, accessToken : Maybe String } -> msg) -> Sub msg


port changeNetworkState : (Bool -> msg) -> Sub msg


port notifyNewVersionAvailable : (String -> msg) -> Sub msg


port openLocalFile : () -> Cmd msg


port openedLocalFile : (( String, String ) -> msg) -> Sub msg


port saveLocalFile : E.Value -> Cmd msg


port savedLocalFile : (String -> msg) -> Sub msg


port closeLocalFile : () -> Cmd msg


port copyText : String -> Cmd msg


port insertText : String -> Cmd msg
