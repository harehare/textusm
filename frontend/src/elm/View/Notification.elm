module View.Notification exposing (docs, view)

import Css
import Css.Transitions as Transitions
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes as Attr
import Style.Breakpoint as Breakpoint
import Style.Color as ColorStyle
import Style.Style as Style
import Style.Text as Text
import Types.Color as Color
import Types.Notification as Notification
import View.Icon as Icon


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
                , Css.position Css.fixed
                , Css.cursor Css.pointer
                , Css.displayFlex
                , Css.alignItems Css.center
                , Css.minWidth <| Css.px 300
                , Css.height <| Css.px 40
                , Css.backgroundColor <| Css.rgba 0 0 0 0.87
                , ColorStyle.textColor
                , Transitions.transition [ Transitions.transform3 100 100 Transitions.easeInOut ]
                , Style.widthScreen
                , Style.shadowNone
                , Css.right <| Css.px 0
                , Css.bottom <| Css.px 0
                , Css.zIndex <| Css.int 200
                , case notification of
                    Notification.Hide ->
                        Css.transform <| Css.translateY <| Css.px 100

                    _ ->
                        Css.transform <| Css.translateY <| Css.pct 10
                ]
                [ Breakpoint.large
                    [ Style.widthAuto
                    , Style.shadowSm
                    , Css.bottom <| Css.px 16
                    , Css.right <| Css.px 16
                    ]
                ]
            ]
        ]
        [ Html.div
            [ Attr.css [ Css.displayFlex, Css.alignItems Css.center, Style.mrMd ]
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
