port module Ports exposing
    ( changeNetworkState
    , changeText
    , closeFullscreen
    , closeLocalFile
    , copyText
    , downloadCompleted
    , focusEditor
    , fullscreen
    , getDiagram
    , getGithubAccessToken
    , gotGithubAccessToken
    , gotLocalDiagramJson
    , gotLocalDiagramsJson
    , hotkey
    , insertText
    , loadSettingsFromLocal
    , loadSettingsFromLocalCompleted
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
    , saveSettingsToLocal
    , saveToLocalCompleted
    , saveToRemote
    , savedLocalFile
    , selectItemFromLineNo
    , sendErrorNotification
    , signIn
    , signOut
    , startDownload
    , updateIdToken
    )

import Json.Decode as D
import Json.Encode as E


port changeNetworkState : (Bool -> msg) -> Sub msg


port changeText : (String -> msg) -> Sub msg


port closeFullscreen : () -> Cmd msg


port closeLocalFile : () -> Cmd msg


port copyText : String -> Cmd msg


port downloadCompleted : (( Int, Int ) -> msg) -> Sub msg


port focusEditor : () -> Cmd msg


port fullscreen : (Bool -> msg) -> Sub msg


port getDiagram : String -> Cmd msg


port getGithubAccessToken : String -> Cmd msg


port gotGithubAccessToken : ({ cmd : String, accessToken : Maybe String } -> msg) -> Sub msg


port gotLocalDiagramJson : (D.Value -> msg) -> Sub msg


port gotLocalDiagramsJson : (D.Value -> msg) -> Sub msg


port insertText : String -> Cmd msg


port loadSettingsFromLocal : String -> Cmd msg


port loadSettingsFromLocalCompleted : (D.Value -> msg) -> Sub msg


port notifyNewVersionAvailable : (String -> msg) -> Sub msg


port onAuthStateChanged : (Maybe D.Value -> msg) -> Sub msg


port onNotification : (String -> msg) -> Sub msg


port onWarnNotification : (String -> msg) -> Sub msg


port openFullscreen : () -> Cmd msg


port openLocalFile : () -> Cmd msg


port openedLocalFile : (( String, String ) -> msg) -> Sub msg


port progress : (Bool -> msg) -> Sub msg


port refreshToken : () -> Cmd msg


port reload : (String -> msg) -> Sub msg


port removeRemoteDiagram : (D.Value -> msg) -> Sub msg


port saveDiagram : E.Value -> Cmd msg


port saveLocalFile : E.Value -> Cmd msg


port saveSettingsToLocal : E.Value -> Cmd msg


port saveToLocalCompleted : (D.Value -> msg) -> Sub msg


port saveToRemote : (D.Value -> msg) -> Sub msg


port savedLocalFile : (String -> msg) -> Sub msg


port sendErrorNotification : (String -> msg) -> Sub msg


port hotkey : (String -> msg) -> Sub msg


port signIn : String -> Cmd msg


port signOut : () -> Cmd msg


port startDownload : ({ extension : String, mimeType : String, content : String } -> msg) -> Sub msg


port updateIdToken : (String -> msg) -> Sub msg


port selectItemFromLineNo : ({ lineNo : Int, text : String } -> msg) -> Sub msg
