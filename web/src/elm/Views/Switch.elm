module Views.Switch exposing (view)

import Html exposing (Html, div, input, label)
import Html.Attributes exposing (checked, class, type_)
import Html.Events as E


view : Bool -> (Bool -> msg) -> Html msg
view check onCheck =
    div [ class "switch" ]
        [ input
            [ type_ "checkbox"
            , class "switch-input"
            , checked check
            , E.onCheck onCheck
            ]
            []
        , label [ class "switch-label" ] []
        ]
