module Dialog.Input exposing (view)

import Events
import Html exposing (Html, button, div, input, text)
import Html.Attributes exposing (class, maxlength, placeholder, style, type_, value)
import Html.Events exposing (onClick, onInput)
import Views.Empty as Empty
import Views.Spinner as Spinner


type alias Props msg =
    { title : String
    , errorMessage : Maybe String
    , value : String
    , inProcess : Bool
    , onInput : String -> msg
    , onEnter : msg
    }


view : Props msg -> Html msg
view props =
    div [ class "dialog" ]
        [ div [ class "input-dialog" ]
            [ div [ class "font-bold", style "padding" "0 8px" ] [ text props.title ]
            , div [ class "flex flex-col items-center justify-center", style "padding" "8px" ]
                [ input
                    [ class "input-light text-sm"
                    , type_ "password"
                    , placeholder "Enter password"
                    , style "color" "#555"
                    , style "width" "305px"
                    , case props.errorMessage of
                        Just _ ->
                            style "border" "3px solid var(--error-color)"

                        Nothing ->
                            style "" ""
                    , maxlength 72
                    , value props.value
                    , onInput props.onInput
                    , if props.inProcess then
                        style "" ""

                      else
                        Events.onEnter props.onEnter
                    ]
                    []
                , case props.errorMessage of
                    Just msg ->
                        div [ class "w-full text-sm font-bold text-right", style "color" "var(--error-color)" ] [ text msg ]

                    Nothing ->
                        Empty.view
                , button
                    [ type_ "button"
                    , class "button submit"
                    , style "margin-top" "8px"
                    , style "border-radius" "8px"
                    , if props.inProcess then
                        style "" ""

                      else
                        onClick props.onEnter
                    ]
                    [ if props.inProcess then
                        div [ class "w-full flex-center" ] [ Spinner.small ]

                      else
                        text "Submit"
                    ]
                ]
            ]
        ]
