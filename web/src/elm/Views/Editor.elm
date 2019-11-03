module Views.Editor exposing (view)

import Html exposing (Html, div)
import Html.Attributes exposing (id, style)
import Models.Model exposing (Msg)
import Route exposing (Route(..))
import Styles


view : Html Msg
view =
    div
        (style "background-color" "#273037" :: Styles.matchParent)
        [ div
            (Styles.matchParent
                ++ [ id "editor"
                   ]
            )
            []
        ]
