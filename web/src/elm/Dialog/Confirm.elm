module Dialog.Confirm exposing (view)

import Html exposing (Html, button, div, text)
import Html.Attributes exposing (class, style, type_)
import Html.Events exposing (onClick)


type alias ButtonConfig msg =
    { text : String
    , onClick : msg
    }


type alias Props msg =
    { title : String
    , message : String
    , okButton : ButtonConfig msg
    , cancelButton : ButtonConfig msg
    }


view : Props msg -> Html msg
view { title, message, okButton, cancelButton } =
    div [ class "dialog" ]
        [ div [ class "confirm-dialog" ]
            [ div [ class "text-lg font-bold py-2" ] [ text title ]
            , div [ class "py-3" ] [ text message ]
            , div [ class "flex items-center justify-center gap-4" ]
                [ button
                    [ type_ "button"
                    , class "button submit"
                    , style "margin-top" "8px"
                    , style "border-radius" "8px"
                    , onClick okButton.onClick
                    ]
                    [ text okButton.text ]
                , button
                    [ type_ "button"
                    , class "button submit bg-disabled text-dark"
                    , style "margin-top" "8px"
                    , style "border-radius" "8px"
                    , onClick cancelButton.onClick
                    ]
                    [ text cancelButton.text ]
                ]
            ]
        ]
