module Views.Notification exposing (showErrorMessage, showInfoMessage, showWarningMessage, view)

import Html exposing (Html, div, text)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick)
import Models.Model exposing (Msg(..), Notification(..))
import Task
import Views.Icon as Icon


view : Notification -> Html Msg
view notification =
    let
        ( t, icon ) =
            case notification of
                Info text ->
                    ( text, Icon.info 22 )

                Error text ->
                    ( text, Icon.error 22 )

                Warning text ->
                    ( text, Icon.warning 22 )
    in
    div
        [ class "notification"
        , onClick OnCloseNotification
        ]
        [ div
            [ style "display" "flex"
            , style "align-items" "center"
            , style "margin-right" "16px"
            ]
            [ div
                [ style "margin-left" "8px"
                ]
                [ icon ]
            , div
                [ style "margin-left" "8px"
                ]
                [ text t ]
            ]
        , div
            [ class "close"
            , onClick OnCloseNotification
            ]
            []
        ]


showWarningMessage : String -> Cmd Msg
showWarningMessage msg =
    Task.perform identity (Task.succeed (OnNotification (Warning msg)))


showInfoMessage : String -> Cmd Msg
showInfoMessage msg =
    Task.perform identity (Task.succeed (OnNotification (Info msg)))


showErrorMessage : String -> Cmd Msg
showErrorMessage msg =
    Task.perform identity (Task.succeed (OnNotification (Error msg)))
