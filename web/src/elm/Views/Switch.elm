module Views.Switch exposing (view)

import Html exposing (Html, div, input, label)
import Html.Attributes exposing (class, type_)
import Html.Events as E


view : (Bool -> msg) -> Html msg
view onCheck =
    div [ class "switch" ]
        [ input [ type_ "checkbox", class "switch-input", E.onCheck onCheck ] []
        , label [ class "switch-label" ] []
        ]
