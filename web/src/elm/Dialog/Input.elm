module Dialog.Input exposing (view)

import Events
import Html exposing (Html, div, input, text)
import Html.Attributes exposing (class, placeholder, style, type_, value)
import Html.Events exposing (onInput)


type alias Props msg =
    { title : String
    , value : String
    , onInput : String -> msg
    , onEnter : msg
    }


view : Props msg -> Html msg
view props =
    div [ class "dialog" ]
        [ div [ class "input-dialog" ]
            [ div [ style "padding" "8px" ] [ text props.title ]
            , div [ style "padding" "8px" ]
                [ input
                    [ class "input-light text-sm"
                    , type_ "password"
                    , placeholder "Password"
                    , style "color" "#555"
                    , style "width" "305px"
                    , value props.value
                    , onInput props.onInput
                    , Events.onEnter props.onEnter
                    ]
                    []
                ]
            ]
        ]
