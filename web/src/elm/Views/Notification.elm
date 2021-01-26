module Views.Notification exposing (view)

import Html exposing (Html, div, text)
import Html.Attributes exposing (class, style)
import Maybe.Extra exposing (isNothing)
import Models.Model exposing (Msg(..), Notification(..))
import Views.Icon as Icon


view : Maybe Notification -> Html msg
view notification =
    let
        ( t, icon ) =
            case notification of
                Just (Info text) ->
                    ( text, Icon.info 22 )

                Just (Error text) ->
                    ( text, Icon.error 22 )

                Just (Warning text) ->
                    ( text, Icon.warning 22 )

                Nothing ->
                    ( "", Icon.info 0 )
    in
    div
        [ class <|
            "notification"
                ++ (if isNothing notification then
                        ""

                    else
                        " show-notification"
                   )
        ]
        [ div
            [ class "flex items-center"
            , style "margin-right" "16px"
            ]
            [ div [ style "margin-left" "8px" ] [ icon ]
            , div [ style "margin-left" "8px" ] [ text t ]
            ]
        ]
