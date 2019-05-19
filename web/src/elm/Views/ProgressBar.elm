module Views.ProgressBar exposing (view)

import Html exposing (Html, div)
import Html.Attributes exposing (class)
import Models.Model exposing (Msg(..))


view : Html Msg
view =
    div [ class "progress" ] [ div [ class "indeterminate" ] [] ]
