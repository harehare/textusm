port module Subscriptions exposing (applySettings, changeText, decodeShareText, downloadPng, downloadSvg, editSettings, encodeShareText, errorLine, layoutEditor, loadEditor, loadText, saveSettings, selectLine, subscriptions)

import Browser.Events exposing (onMouseMove, onMouseUp, onResize, onVisibilityChange)
import Json.Decode as D
import Models.Figure as Figure
import Models.Model exposing (Download, Model, Msg(..), Notification(..), Settings, ShareInfo)


port changeText : (String -> msg) -> Sub msg


port startDownloadSvg : (String -> msg) -> Sub msg


port applySettings : (Settings -> msg) -> Sub msg


port onDecodeShareText : (String -> msg) -> Sub msg


port onEncodeShareText : (String -> msg) -> Sub msg


port onNotification : (String -> msg) -> Sub msg


port downloadPng : Download -> Cmd msg


port downloadSvg : Download -> Cmd msg


port loadEditor : String -> Cmd msg


port loadText : String -> Cmd msg


port layoutEditor : Int -> Cmd msg


port saveSettings : Settings -> Cmd msg


port selectLine : String -> Cmd msg


port errorLine : String -> Cmd msg


port editSettings : Settings -> Cmd msg


port decodeShareText : String -> Cmd msg


port encodeShareText : ShareInfo -> Cmd msg


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        ([ changeText (\text -> UpdateFigure (Figure.OnChangeText text))
         , applySettings ApplySettings
         , startDownloadSvg StartDownloadSvg
         , onVisibilityChange OnVisibilityChange
         , onResize (\width height -> UpdateFigure (Figure.OnResize width height))
         , onMouseUp (D.succeed (UpdateFigure Figure.Stop))
         , onEncodeShareText OnEncodeShareText
         , onDecodeShareText OnDecodeShareText
         , onNotification (\n -> OnNotification (Info n Nothing))
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
