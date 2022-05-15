module Views.Diagram.Search exposing (view)

import Css
    exposing
        ( backgroundColor
        , border3
        , cursor
        , hex
        , marginTop
        , padding2
        , padding4
        , pointer
        , px
        , rgba
        , solid
        , width
        )
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes exposing (autofocus, css, placeholder, value)
import Html.Styled.Events as Events
import Models.Color as Color
import Style.Style as Style
import Style.Text as TextStyle
import Views.Icon as Icon


view : { query : String, searchMsg : String -> msg, closeMsg : msg } -> Html msg
view { query, searchMsg, closeMsg } =
    Html.div
        [ css
            [ Style.roundedSm
            , padding4 (px 4) (px 4) (px 4) (px 16)
            , border3 (px 1) solid (rgba 0 0 0 0.1)
            , Style.flexSpace
            , backgroundColor <| hex <| Color.toString Color.white2
            , width <| px 252
            ]
        ]
        [ Html.input
            [ css
                [ Style.inputLight
                , TextStyle.sm
                , Style.paddingXs
                , width <| px 240
                ]
            , Events.onInput searchMsg
            , placeholder "Search"
            , value query
            , autofocus True
            ]
            []
        , Html.div
            [ css [ padding2 (px 8) (px 8), marginTop (px 4), cursor pointer ], Events.onClick closeMsg ]
            [ Icon.clear (Color.toString Color.gray) 20 ]
        ]
