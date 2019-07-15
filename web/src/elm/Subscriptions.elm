port module Subscriptions exposing (applySettings, changeText, copyClipboard, decodeShareText, downloadPng, downloadSvg, editSettings, encodeShareText, errorLine, getAccessTokenForGitHub, getDiagram, getDiagrams, layoutEditor, loadEditor, loadText, login, logout, removeDiagrams, saveDiagram, saveSettings, selectLine, selectTextById, subscriptions)

import Browser.Events exposing (onMouseMove, onMouseUp, onResize, onVisibilityChange)
import Json.Decode as D
import Models.Diagram as DiagramModel
import Models.DiagramItem exposing (DiagramItem)
import Models.Model exposing (Download, Model, Msg(..), Notification(..), Settings, ShareInfo)
import Models.User exposing (User)


port changeText : (String -> msg) -> Sub msg


port onAuthStateChanged : (Maybe User -> msg) -> Sub msg


port startDownloadSvg : (String -> msg) -> Sub msg


port applySettings : (Settings -> msg) -> Sub msg


port onDecodeShareText : (String -> msg) -> Sub msg


port onEncodeShareText : (String -> msg) -> Sub msg


port onNotification : (String -> msg) -> Sub msg


port onErrorNotification : (String -> msg) -> Sub msg


port onWarnNotification : (String -> msg) -> Sub msg


port shortcuts : (String -> msg) -> Sub msg


port offline : (() -> msg) -> Sub msg


port online : (() -> msg) -> Sub msg


port moveTo : (String -> msg) -> Sub msg


port removeRemoteDiagram : (DiagramItem -> msg) -> Sub msg


port downloadPng : Download -> Cmd msg


port downloadSvg : Download -> Cmd msg


port loadEditor : String -> Cmd msg


port login : () -> Cmd msg


port logout : () -> Cmd msg


port loadText : String -> Cmd msg


port layoutEditor : Int -> Cmd msg


port saveSettings : Settings -> Cmd msg


port selectLine : Int -> Cmd msg


port errorLine : String -> Cmd msg


port editSettings : Settings -> Cmd msg


port decodeShareText : String -> Cmd msg


port encodeShareText : ShareInfo -> Cmd msg


port copyClipboard : String -> Cmd msg


port selectTextById : String -> Cmd msg


port getAccessTokenForGitHub : () -> Cmd msg


port onGetAccessTokenForGitHub : (String -> msg) -> Sub msg



-- Diagram


port saveDiagram : ( DiagramItem, Maybe String ) -> Cmd msg


port removeDiagrams : DiagramItem -> Cmd msg


port getDiagrams : () -> Cmd msg


port getDiagram : String -> Cmd msg


port loadLocalDiagrams : (List DiagramItem -> msg) -> Sub msg


port removedDiagram : (( DiagramItem, Bool ) -> msg) -> Sub msg


port saveToRemote : (DiagramItem -> msg) -> Sub msg


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        ([ changeText (\text -> UpdateDiagram (DiagramModel.OnChangeText text))
         , applySettings ApplySettings
         , startDownloadSvg StartDownloadSvg
         , loadLocalDiagrams LoadLocalDiagrams
         , removedDiagram RemovedDiagram
         , onVisibilityChange OnVisibilityChange
         , onResize (\width height -> UpdateDiagram (DiagramModel.OnResize width height))
         , onMouseUp (D.succeed (UpdateDiagram DiagramModel.Stop))
         , onEncodeShareText OnEncodeShareText
         , onDecodeShareText OnDecodeShareText
         , shortcuts Shortcuts
         , onNotification (\n -> OnAutoCloseNotification (Info n Nothing))
         , onErrorNotification (\n -> OnAutoCloseNotification (Error n))
         , onWarnNotification (\n -> OnAutoCloseNotification (Warning n Nothing))
         , onAuthStateChanged OnAuthStateChanged
         , onGetAccessTokenForGitHub ExportGitHub
         , saveToRemote SaveToRemote
         , offline (\_ -> OnChangeNetworkStatus False)
         , online (\_ -> OnChangeNetworkStatus True)
         , removeRemoteDiagram RemoveRemoteDiagram
         , moveTo MoveTo
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
