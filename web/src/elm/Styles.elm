module Styles exposing (flex, flexCenter, matchParent, title)

import Html
import Html.Attributes exposing (style)
import Models.Model exposing (Msg)


title : List (Html.Attribute Msg)
title =
    [ style "font-family" "'Open Sans', apple-system, BlinkMacSystemFont, Helvetica Neue, Hiragino Kaku Gothic ProN, 游ゴシック Medium, YuGothic, YuGothicM, メイリオ, Meiryo, sans-serif"
    , style "font-size" "2.5rem"
    , style "padding" "8px"
    , style "color" "#333333"
    ]


flex : List (Html.Attribute Msg)
flex =
    [ style "display" "flex"
    ]


flexCenter : List (Html.Attribute Msg)
flexCenter =
    flex
        ++ [ style "align-items" "center"
           ]


matchParent : List (Html.Attribute Msg)
matchParent =
    [ style "width" "100%"
    , style "height" "100%"
    ]
