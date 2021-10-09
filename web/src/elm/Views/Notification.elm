module Views.Notification exposing (view)

import Html exposing (Html)
import Html.Attributes as Attr
import Models.Model exposing (Msg(..))
import Models.Notification exposing (Notification(..), NotificationState(..))
import Views.Icon as Icon


view : NotificationState -> Html msg
view notification =
    let
        ( text_, icon ) =
            case notification of
                Show (Info text) ->
                    ( text, Icon.info 22 )

                Show (Error text) ->
                    ( text, Icon.error 22 )

                Show (Warning text) ->
                    ( text, Icon.warning 22 )

                Hide ->
                    ( "", Icon.info 0 )
    in
    Html.div
        [ Attr.class "notification"
        , case notification of
            Hide ->
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
