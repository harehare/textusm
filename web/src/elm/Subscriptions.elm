port module Subscriptions exposing (applySettings, changeText, decodeShareText, downloadPng, downloadSvg, editSettings, encodeShareText, errorLine, getDiagram, getDiagrams, layoutEditor, loadEditor, loadText, removeDiagrams, saveDiagram, saveSettings, selectLine, subscriptions)

import Browser.Events exposing (onMouseMove, onMouseUp, onResize, onVisibilityChange)
import Json.Decode as D
import Models.Diagram as DiagramModel
import Models.Model exposing (Diagram, Download, Model, Msg(..), Notification(..), Settings, ShareInfo)


port changeText : (String -> msg) -> Sub msg


port startDownloadSvg : (String -> msg) -> Sub msg


port applySettings : (Settings -> msg) -> Sub msg


port onDecodeShareText : (String -> msg) -> Sub msg


port onEncodeShareText : (String -> msg) -> Sub msg


port onNotification : (String -> msg) -> Sub msg


port shortcuts : (String -> msg) -> Sub msg


port downloadPng : Download -> Cmd msg


port downloadSvg : Download -> Cmd msg


port loadEditor : String -> Cmd msg


port loadText : ( String, Bool ) -> Cmd msg


port layoutEditor : Int -> Cmd msg


port saveSettings : Settings -> Cmd msg


port selectLine : String -> Cmd msg


port errorLine : String -> Cmd msg


port editSettings : Settings -> Cmd msg


port decodeShareText : String -> Cmd msg


port encodeShareText : ShareInfo -> Cmd msg



-- Diagram


port saveDiagram : Diagram -> Cmd msg



-- TODO: remove params


port removeDiagrams : Diagram -> Cmd msg


port getDiagrams : () -> Cmd msg


port getDiagram : String -> Cmd msg


port showDiagrams : (List Diagram -> msg) -> Sub msg


port removedDiagram : (Bool -> msg) -> Sub msg


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        ([ changeText (\text -> UpdateDiagram (DiagramModel.OnChangeText text))
         , applySettings ApplySettings
         , startDownloadSvg StartDownloadSvg
         , showDiagrams ShowDiagrams
         , removedDiagram RemovedDiagram
         , onVisibilityChange OnVisibilityChange
         , onResize (\width height -> UpdateDiagram (DiagramModel.OnResize width height))
         , onMouseUp (D.succeed (UpdateDiagram DiagramModel.Stop))
         , onEncodeShareText OnEncodeShareText
         , onDecodeShareText OnDecodeShareText
         , shortcuts Shortcuts
         , onNotification (\n -> OnAutoCloseNotification (Info n Nothing))
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
