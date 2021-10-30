module Views.SwitchWindow exposing (view)

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events exposing (onClick)
import Models.Model exposing (WindowState(..))
import Views.Empty as Empty
import Views.Icon as Icon


view : (WindowState -> msg) -> String -> WindowState -> Html msg -> Html msg -> Html msg
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
                Editor ->
                    onClick (onSwitchWindow Preview)

                Preview ->
                    onClick (onSwitchWindow Editor)

                _ ->
                    Attr.class ""
            ]
            [ case window of
                Editor ->
                    Icon.visibility 20

                Preview ->
                    Icon.edit 20

                _ ->
                    Empty.view
            ]
        , Html.div
            [ Attr.class "h-main lg:h-full w-full" ]
            [ Html.div
                [ case window of
                    Editor ->
                        Attr.class "block"

                    Preview ->
                        Attr.class "hidden"

                    _ ->
                        Attr.class ""
                , Attr.class "full"
                ]
                [ view1 ]
            , Html.div
                [ case window of
                    Preview ->
                        Attr.class "block"

                    Editor ->
                        Attr.class "hidden"

                    _ ->
                        Attr.class ""
                , Attr.style "background-color" backgroundColor
                , Attr.class "full"
                ]
                [ view2 ]
            ]
        ]
