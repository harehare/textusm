module Views.ProgressBar exposing (view)

import Html exposing (Html, div)
import Html.Attributes exposing (class)


view : Html msg
view =
    div [ class "progress" ] [ div [ class "indeterminate" ] [] ]
