module Views.SplitWindow exposing (view)

import Html exposing (Attribute, Html, div)
import Html.Attributes exposing (class, style)
import Html.Events as Events
import Json.Decode as D
import Models.Model exposing (Window)


view : (Int -> msg) -> String -> Window -> Html msg -> Html msg -> Html msg
view onResize backgroundColor window left right =
    let
        ( leftPos, rightPos ) =
            if window.position > 0 then
                ( "calc((100vw - 56px) / 2 + "
                    ++ String.fromInt (abs window.position)
                    ++ "px)"
                , "calc((100vw - 56px) / 2 - "
                    ++ String.fromInt (abs window.position)
                    ++ "px)"
                )

            else if window.position < 0 then
                ( "calc((100vw - 56px) / 2 - "
                    ++ String.fromInt (abs window.position)
                    ++ "px)"
                , "calc((100vw - 56px) / 2 + "
                    ++ String.fromInt (abs window.position)
                    ++ "px)"
                )

            else
                ( "calc((100vw - 56px) / 2)", "calc((100vw - 56px) / 2)" )
    in
    if window.fullscreen then
        div
            [ style "display" "flex", style "background-color" backgroundColor ]
            [ div
                [ style "display" "none"
                ]
                [ left ]
            , div
                [ style "width"
                    "100vw"
                , style
                    "height"
                    "100vh"
                ]
                [ right ]
            ]

    else
        div
            [ style "display" "flex" ]
            [ div
                [ style "width"
                    leftPos
                , style
                    "height"
                    "calc(100vh - 40px)"
                , style "background-color" "#273037"
                ]
                [ left ]
            , div
                [ style "width" "6px"
                , style "cursor" "col-resize"
                , style "background-color" "var(--main-color)"
                , onStartWindowResize onResize
                ]
                []
            , div
                [ style "width"
                    rightPos
                , style
                    "height"
                    "calc(100vh - 40px)"
                , style "background-color" backgroundColor
                ]
                [ right ]
            ]


onStartWindowResize : (Int -> msg) -> Attribute msg
onStartWindowResize e =
    Events.on "mousedown" (D.map e pageX)


pageX : D.Decoder Int
pageX =
    D.field "pageX" D.int
