module Views.Notification exposing (view)

import Css
    exposing
        ( alignItems
        , backgroundColor
        , bottom
        , center
        , cursor
        , displayFlex
        , fixed
        , height
        , int
        , minWidth
        , pct
        , pointer
        , position
        , px
        , rgba
        , right
        , transform
        , translateY
        , zIndex
        )
import Css.Media as Media exposing (withMedia)
import Css.Transitions as Transitions
import Html.Styled as Html exposing (Html, text)
import Html.Styled.Attributes exposing (css)
import Models.Notification as Notification
import Style.Color as Color
import Style.Style as Style
import Style.Text as Text
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
        [ css
            [ Text.sm
            , position fixed
            , cursor pointer
            , displayFlex
            , alignItems center
            , zIndex <| int 50
            , minWidth <| px 300
            , height <| px 40
            , bottom <| px 16
            , right <| px 16
            , backgroundColor <| rgba 0 0 0 0.87
            , Color.textColor
            , Style.shadowSm
            , Transitions.transition [ Transitions.transform3 100 100 Transitions.easeInOut ]
            , case notification of
                Notification.Hide ->
                    transform <| translateY <| px 100

                _ ->
                    transform <| translateY <| pct 10
            , withMedia [ Media.all [ Media.maxWidth (px 480) ] ]
                [ Style.widthScreen
                , Style.shadowNone
                , right <| px 0
                , bottom <| px 55
                , zIndex <| int 200
                ]
            ]
        ]
        [ Html.div
            [ css [ displayFlex, alignItems center, Style.mrMd ]
            ]
            [ Html.div [ css [ Style.mlSm ] ] [ icon ]
            , Html.div [ css [ Style.mlSm ] ] [ Html.text text_ ]
            ]
        ]
