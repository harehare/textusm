module Views.Spinner exposing (small)

import Html exposing (Html, div)
import Html.Attributes exposing (class)


small : Html msg
small =
    div [ class "loader" ] []
