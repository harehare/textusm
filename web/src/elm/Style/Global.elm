module Style.Global exposing (..)

import Css
    exposing
        ( absolute
        , backgroundColor
        , bottom
        , center
        , display
        , hex
        , hidden
        , inlineBlock
        , int
        , left
        , marginLeft
        , opacity
        , padding2
        , position
        , px
        , right
        , textAlign
        , top
        , visibility
        , width
        , zIndex
        )
import Css.Global exposing (children, class, global)
import Css.Transitions as Transitions exposing (transition)
import Html.Styled exposing (Html)
import Style.Color as Color
import Style.Style as Style
import Style.Text as Text


style : Html msg
style =
    global
        [ class "bottom-tooltip"
            [ visibility hidden
            , textAlign center
            , position absolute
            , opacity <| int 0
            , zIndex <| int 10
            , transition [ Transitions.opacity 500 ]
            , width <| px 120
            , top <| px 32
            , right <| px -48
            , children
                [ class "text"
                    [ Text.sm
                    , Color.textColor
                    , display inlineBlock
                    , backgroundColor <| hex "#333333"
                    , padding2 (px 5) (px 10)
                    , Style.roundedSm
                    ]
                ]
            ]
        , class "tooltip"
            [ visibility hidden
            , textAlign center
            , position absolute
            , opacity <| int 0
            , zIndex <| int 10
            , transition [ Transitions.opacity 500 ]
            , width <| px 120
            , left <| px 80
            , bottom <| px -8
            , marginLeft <| px -60
            , children
                [ class "text"
                    [ Text.sm
                    , Color.textColor
                    , display inlineBlock
                    , backgroundColor <| hex "#333333"
                    , padding2 (px 5) (px 10)
                    , Style.roundedSm
                    ]
                ]
            ]
        ]
