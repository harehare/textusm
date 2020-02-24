module Views.SwitchWindow exposing (view)

import Html exposing (Html, div)
import Html.Attributes exposing (style)
import Html.Events exposing (onClick)
import Models.Model exposing (Msg(..))
import Views.Icon as Icon


view : String -> Int -> Html Msg -> Html Msg -> Html Msg
view backgroundColor index view1 view2 =
    div
        [ style "width" "100vw"
        , style "flex-direction" "column"
        , style "backgrond-color" "#282C32"
        , style "position" "relative"
        , style "display" "flex"
        ]
        [ div
            [ style "position" "fixed"
            , style "bottom" "72px"
            , style "z-index" "101"
            , style "background-color" "var(--accent-color)"
            , style "display" "flex"
            , style "align-items" "center"
            , style "justify-content" "center"
            , style "right" "16px"
            , style "padding" "12px"
            , style "border-radius" "100%"
            , style "box-shadow" "0 1px 4px rgba(0, 0, 0, .6)"
            , if index == 1 then
                onClick (WindowSelect 2)

              else
                onClick (WindowSelect 1)
            ]
            [ if index == 1 then
                Icon.visibility 20

              else
                Icon.edit 20
            ]
        , div
            [ style "width" "100%"
            , style "height" "100%"
            ]
            [ div
                [ if index == 1 then
                    style "display" "block"

                  else
                    style "display" "none"
                , style "width" "100%"
                , style "height" "100%"
                ]
                [ view1 ]
            , div
                [ if index == 2 then
                    style "display" "block"

                  else
                    style "display" "none"
                , style "background-color" backgroundColor
                , style "width" "100%"
                , style "height" "100%"
                ]
                [ view2 ]
            ]
        ]
