module Views.Diagram.Search exposing (view)

import Css
    exposing
        ( absolute
        , backgroundColor
        , border3
        , cursor
        , hex
        , marginTop
        , padding2
        , padding4
        , pointer
        , position
        , px
        , rgba
        , right
        , solid
        , top
        , width
        )
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes exposing (autofocus, css, placeholder, value)
import Html.Styled.Events as Events
import Models.Color as Color
import Style.Color as ColorStyle
import Style.Style as Style
import Style.Text as TextStyle
import Views.Icon as Icon


view : { query : String, count : Int, searchMsg : String -> msg, closeMsg : msg } -> Html msg
view { query, searchMsg, count, closeMsg } =
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
        , Html.div
            [ css
                [ position absolute
                , right <| px 48
                , top <| px 20
                , TextStyle.xs
                , ColorStyle.textSecondaryColor
                ]
            ]
            [ Html.text <| String.fromInt count
            ]
        ]
