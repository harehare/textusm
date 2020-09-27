module Page.NotFound exposing (view)

import Asset
import Html exposing (Html, div, img, text)
import Html.Attributes exposing (alt, class, style)


view : Html msg
view =
    div
        [ style "height" "calc(100vh - 40px)"
        , style "width" "100vw"
        , style "display" "flex"
        , style "align-items" "center"
        , style "justify-content" "center"
        , style "color" "var(--text-color)"
        , style "font-size" "1.2rem"
        , style "font-weight" "600"
        , style "margin" "8px"
        ]
        [ img [ class "keyframe anim", Asset.src Asset.logo, style "width" "32px", alt "NOT FOUND" ] []
        , div [ style "padding" "8px" ] [ text "NOT FOUND" ]
        ]
