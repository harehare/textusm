module Views.Notification exposing (view)

import Html exposing (Html)
import Html.Attributes as Attr
import Models.Notification as Notification
import Views.Icon as Icon


view : Notification.Notification -> Html msg
view notification =
    let
        ( text_, icon ) =
            case notification of
                Notification.Show (Notification.Info text) ->
                    ( text, Icon.info 22 )

                Notification.Show (Notification.Error text) ->
                    ( text, Icon.error 22 )

                Notification.Show (Notification.Warning text) ->
                    ( text, Icon.warning 22 )

                Notification.Hide ->
                    ( "", Icon.info 0 )
    in
    Html.div
        [ Attr.class "notification"
        , case notification of
            Notification.Hide ->
                Attr.class ""

            _ ->
                Attr.style "transform" "translateY(10%)"
        ]
        [ Html.div
            [ Attr.class "flex items-center mr-md"
            ]
            [ Html.div [ Attr.class "ml-sm" ] [ icon ]
            , Html.div [ Attr.class "ml-sm" ] [ Html.text text_ ]
            ]
        ]
