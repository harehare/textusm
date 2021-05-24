module Views.SwitchWindow exposing (view)

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events exposing (onClick)
import Models.Model exposing (Msg(..), SwitchWindow(..))
import Views.Icon as Icon


view : (SwitchWindow -> msg) -> String -> SwitchWindow -> Html msg -> Html msg -> Html msg
view onSwitchWindow backgroundColor window view1 view2 =
    Html.div
        [ Attr.class "flex"
        , Attr.class "flex-col"
        , Attr.class "relative"
        , Attr.class "w-screen"
        , Attr.class "bg-main"
        ]
        [ Html.div
            [ Attr.class "fixed"
            , Attr.class "flex-center"
            , Attr.class "rounded-full"
            , Attr.class "bg-accent"
            , Attr.class "z-50"
            , Attr.class "p-sm"
            , Attr.class "shadow-md"
            , Attr.style "bottom" "72px"
            , Attr.style "right" "16px"
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
                        Attr.class "block"

                    Right ->
                        Attr.class "hidden"
                , Attr.class "full"
                ]
                [ view1 ]
            , Html.div
                [ case window of
                    Right ->
                        Attr.class "block"

                    Left ->
                        Attr.class "hidden"
                , Attr.style "background-color" backgroundColor
                , Attr.class "full"
                ]
                [ view2 ]
            ]
        ]
