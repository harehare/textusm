module Views.Logo exposing (view)

import Html exposing (Html, div, img, text)
import Html.Attributes exposing (alt, src, style)
import Models.Model exposing (Msg)
import Styles


view : Html Msg
view =
    div
        (Styles.flexCenter
            ++ Styles.matchParent
            ++ [ style "justify-content" "center"
               , style "class" "select-none"
               ]
        )
        [ div Styles.title [ text "Text" ]
        , div
            [ style "width"
                "82px"
            , style "height"
                "82px"
            , style "display" "flex"
            , style "justify-content" "center"
            , style "align-items" "center"
            ]
            [ img [ src "/images/logo.svg", style "width" "82px", alt "logo" ] [] ]
        , div Styles.title [ text "USM" ]
        ]
