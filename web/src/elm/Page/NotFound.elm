module Page.NotFound exposing (view)

import Html exposing (Html, div, text)
import Html.Attributes exposing (class)


view : Html msg
view =
    div
        [ class "notfound"
        ]
        [ text "NOT FOUND"
        ]
