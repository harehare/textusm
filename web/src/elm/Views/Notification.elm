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
        [ Attr.class "notification"
        , if isNothing notification then
            Attr.class ""

          else
            Attr.style "transform" "translateY(10%)"
        ]
        [ Html.div
            [ Attr.class "flex items-center mr-md"
            ]
            [ Html.div [ Attr.class "ml-sm" ] [ icon ]
            , Html.div [ Attr.class "ml-sm" ] [ Html.text t ]
            ]
        ]
