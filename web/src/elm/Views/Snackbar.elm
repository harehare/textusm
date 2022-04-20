module Views.Snackbar exposing (view)

import Css
    exposing
        ( alignItems
        , backgroundColor
        , bottom
        , center
        , cursor
        , displayFlex
        , fixed
        , int
        , justifyContent
        , left
        , pct
        , pointer
        , position
        , px
        , rem
        , rgba
        , right
        , spaceBetween
        , transform
        , translate2
        , width
        , zIndex
        )
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes exposing (css)
import Html.Styled.Events as Events
import Models.Snackbar as Snackbar
import Style.Breakpoint as Breakpoint
import Style.Color as Color
import Style.Font as Font
import Style.Style as Style
import Style.Text as Text
import Views.Empty as Empty


view : Snackbar.Snackbar msg -> Html msg
view snackbar =
    case snackbar of
        Snackbar.Show model ->
            Html.div
                [ css
                    [ Breakpoint.style
                        [ position fixed
                        , displayFlex
                        , alignItems center
                        , justifyContent spaceBetween
                        , Text.sm
                        , Style.widthScreen
                        , Style.shadowNone
                        , right <| px 0
                        , left <| px 0
                        , bottom <| px 55
                        , zIndex <| int 200
                        , Color.textColor
                        , cursor pointer
                        , zIndex <| int 200
                        , transform <| translate2 (px 0) (pct -50)
                        , backgroundColor <| rgba 0 0 0 0.87
                        ]
                        [ Breakpoint.large
                            [ Style.shadowSm
                            , width <| px 300
                            , left <| pct 40
                            , right <| px 0
                            , bottom <| rem 0.125
                            ]
                        ]
                    ]
                ]
                [ Html.div [ css [ Style.padding3 ] ] [ Html.text model.message ]
                , Html.div
                    [ css [ Style.padding3, Color.textAccent, cursor pointer, Font.fontBold ]
                    , Events.onClick model.action
                    ]
                    [ Html.text model.text ]
                ]

        Snackbar.Hide ->
            Empty.view
