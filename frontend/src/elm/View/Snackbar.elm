module View.Snackbar exposing (docs, view)

import Css
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes as Attr
import Html.Styled.Events as Events
import Style.Breakpoint as Breakpoint
import Style.Color as Color
import Style.Font as Font
import Style.Style as Style
import Style.Text as Text
import Types.Snackbar as Snackbar
import View.Empty as Empty


view : Snackbar.Snackbar msg -> Html msg
view snackbar =
    case snackbar of
        Snackbar.Show model ->
            Html.div
                [ Attr.css
                    [ Breakpoint.style
                        [ Css.position Css.fixed
                        , Css.displayFlex
                        , Css.alignItems Css.center
                        , Css.justifyContent Css.spaceBetween
                        , Text.sm
                        , Style.widthScreen
                        , Style.shadowNone
                        , Css.right <| Css.px 0
                        , Css.left <| Css.px 0
                        , Css.bottom <| Css.px 55
                        , Css.zIndex <| Css.int 200
                        , Color.textColor
                        , Css.cursor Css.pointer
                        , Css.zIndex <| Css.int 200
                        , Css.transform <| Css.translate2 (Css.px 0) (Css.pct -50)
                        , Css.backgroundColor <| Css.rgba 0 0 0 0.87
                        ]
                        [ Breakpoint.large
                            [ Style.shadowSm
                            , Css.width <| Css.px 300
                            , Css.left <| Css.pct 40
                            , Css.right <| Css.px 0
                            , Css.bottom <| Css.rem 0.125
                            ]
                        ]
                    ]
                ]
                [ Html.div [ Attr.css [ Style.padding3 ] ] [ Html.text model.message ]
                , Html.div
                    [ Attr.css [ Style.padding3, Color.textAccent, Css.cursor Css.pointer, Font.fontBold ]
                    , Events.onClick model.action
                    ]
                    [ Html.text model.text ]
                ]

        Snackbar.Hide ->
            Empty.view


docs : Chapter x
docs =
    Chapter.chapter "Snackbar"
        |> Chapter.renderComponentList
            [ ( "Snackbar"
              , view
                    (Snackbar.Show
                        { message = "snackbar"
                        , text = "snackbar"
                        , action = Actions.logAction "Click"
                        }
                    )
                    |> Html.toUnstyled
              )
            ]
