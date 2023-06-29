module Views.Notification exposing (docs, view)

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
import Css.Transitions as Transitions
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes as Attr
import Models.Color as Color
import Models.Notification as Notification
import Style.Breakpoint as Breakpoint
import Style.Color as ColorStyle
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
                    ( text, Icon.warning Color.warning 22 )

                Notification.Hide ->
                    ( "", Icon.info 0 )
    in
    Html.div
        [ Attr.css
            [ Breakpoint.style
                [ Text.sm
                , position fixed
                , cursor pointer
                , displayFlex
                , alignItems center
                , minWidth <| px 300
                , height <| px 40
                , backgroundColor <| rgba 0 0 0 0.87
                , ColorStyle.textColor
                , Transitions.transition [ Transitions.transform3 100 100 Transitions.easeInOut ]
                , Style.widthScreen
                , Style.shadowNone
                , right <| px 0
                , bottom <| px 0
                , zIndex <| int 200
                , case notification of
                    Notification.Hide ->
                        transform <| translateY <| px 100

                    _ ->
                        transform <| translateY <| pct 10
                ]
                [ Breakpoint.large
                    [ Style.widthAuto
                    , Style.shadowSm
                    , bottom <| px 16
                    , right <| px 16
                    ]
                ]
            ]
        ]
        [ Html.div
            [ Attr.css [ displayFlex, alignItems center, Style.mrMd ]
            ]
            [ Html.div [ Attr.css [ Style.mlSm ] ] [ icon ]
            , Html.div [ Attr.css [ Style.mlSm ] ] [ Html.text text_ ]
            ]
        ]


docs : Chapter x
docs =
    Chapter.chapter "Notification"
        |> Chapter.renderComponentList
            [ ( "info", view (Notification.Show (Notification.Info "info")) |> Html.toUnstyled )
            , ( "warning", view (Notification.Show (Notification.Warning "Warning")) |> Html.toUnstyled )
            , ( "error", view (Notification.Show (Notification.Error "Error")) |> Html.toUnstyled )
            ]
