module Views.Editor exposing (view)

import Html exposing (Html, div)
import Html.Attributes exposing (id, style)
import Models.Model exposing (Msg)
import Styles


view : Bool -> Html Msg
view isEditSettings =
    div
        Styles.matchParent
        [ div
            (Styles.matchParent
                ++ [ id "editor"
                   , if isEditSettings then
                        style "display" "none"

                     else
                        style "display" "block"
                   ]
            )
            []
        , div
            (Styles.matchParent
                ++ [ id "settings"
                   , if isEditSettings then
                        style "display" "block"

                     else
                        style "display" "none"
                   ]
            )
            []
        ]
