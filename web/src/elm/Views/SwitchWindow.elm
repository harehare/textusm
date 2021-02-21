module Views.SwitchWindow exposing (view)

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events exposing (onClick)
import Models.Model exposing (Msg(..), SwitchWindow(..))
import Views.Icon as Icon


view : (SwitchWindow -> msg) -> String -> SwitchWindow -> Html msg -> Html msg -> Html msg
view onSwitchWindow backgroundColor window view1 view2 =
    Html.div [ Attr.class "flex flex-col relative w-screen bg-main" ]
        [ Html.div
            [ Attr.class "fixed flex-center rounded-full bg-accent"
            , Attr.style "bottom" "72px"
            , Attr.style "z-index" "101"
            , Attr.style "right" "16px"
            , Attr.style "padding" "12px"
            , Attr.style "box-shadow" "0 1px 4px rgba(0, 0, 0, .6)"
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
        , Html.div
            [ Attr.class "h-main lg:h-full w-full" ]
            [ Html.div
                [ case window of
                    Left ->
                        Attr.style "display" "block"

                    Right ->
                        Attr.style "display" "none"
                , Attr.class "full"
                ]
                [ view1 ]
            , Html.div
                [ case window of
                    Right ->
                        Attr.style "display" "block"

                    Left ->
                        Attr.style "display" "none"
                , Attr.style "background-color" backgroundColor
                , Attr.class "full"
                ]
                [ view2 ]
            ]
        ]
