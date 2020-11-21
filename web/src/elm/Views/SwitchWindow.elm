module Views.SwitchWindow exposing (view)

import Html exposing (Html, div)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick)
import Models.Model exposing (Msg(..), SwitchWindow(..))
import Views.Icon as Icon


view : (SwitchWindow -> msg) -> String -> SwitchWindow -> Html msg -> Html msg -> Html msg
view onSwitchWindow backgroundColor window view1 view2 =
    div [ class "flex flex-col relative w-screen bg-main" ]
        [ div
            [ class "fixed flex-center rounded-full bg-accent"
            , style "bottom" "72px"
            , style "z-index" "101"
            , style "right" "16px"
            , style "padding" "12px"
            , style "box-shadow" "0 1px 4px rgba(0, 0, 0, .6)"
            , case window of
                Left ->
                    onClick (onSwitchWindow Right)

                Right ->
                    onClick (onSwitchWindow Left)
            ]
            [ case window of
                Left ->
                    Icon.visibility 20

                Right ->
                    Icon.edit 20
            ]
        , div
            [ class "h-main lg:h-full w-full" ]
            [ div
                [ case window of
                    Left ->
                        style "display" "block"

                    Right ->
                        style "display" "none"
                , class "full"
                ]
                [ view1 ]
            , div
                [ case window of
                    Right ->
                        style "display" "block"

                    Left ->
                        style "display" "none"
                , style "background-color" backgroundColor
                , class "full"
                ]
                [ view2 ]
            ]
        ]
