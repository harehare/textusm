module Views.Notification exposing (view)

import Html exposing (Html)
import Html.Attributes as Attr
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
    Html.div
        [ Attr.class <|
            "notification"
                ++ (if isNothing notification then
                        ""

                    else
                        " show-notification"
                   )
        ]
        [ Html.div
            [ Attr.class "flex items-center"
            , Attr.style "margin-right" "16px"
            ]
            [ Html.div [ Attr.style "margin-left" "8px" ] [ icon ]
            , Html.div [ Attr.style "margin-left" "8px" ] [ Html.text t ]
            ]
        ]
