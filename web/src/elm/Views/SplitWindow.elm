module Views.SplitWindow exposing (view)

import Html exposing (Attribute, Html)
import Html.Attributes as Attr
import Html.Events as Events
import Json.Decode as D
import Models.Model exposing (Window)


view : (Int -> msg) -> String -> Window -> Html msg -> Html msg -> Html msg
view onResize backgroundColor window left right =
    let
        ( leftPos, rightPos ) =
            if window.position > 0 then
                ( "calc((100vw - 40px) / 2 + "
                    ++ String.fromInt (abs window.position)
                    ++ "px)"
                , "calc((100vw - 40px) / 2 - "
                    ++ String.fromInt (abs window.position)
                    ++ "px)"
                )

            else if window.position < 0 then
                ( "calc((100vw - 40px) / 2 - "
                    ++ String.fromInt (abs window.position)
                    ++ "px)"
                , "calc((100vw - 40px) / 2 + "
                    ++ String.fromInt (abs window.position)
                    ++ "px)"
                )

            else
                ( "calc((100vw - 40px) / 2)", "calc((100vw - 40px) / 2)" )
    in
    if window.fullscreen then
        Html.div
            [ Attr.class "flex", Attr.style "background-color" backgroundColor ]
            [ Html.div [ Attr.class "hidden" ] [ left ]
            , Html.div [ Attr.class "full-screen" ] [ right ]
            ]

    else
        Html.div
            [ Attr.class "flex" ]
            [ Html.div
                [ Attr.style "width"
                    leftPos
                , Attr.style
                    "height"
                    "calc(100vh - 40px)"
                , Attr.style "background-color" "#273037"
                ]
                [ left ]
            , Html.div
                [ Attr.class "bg-main"
                , Attr.style "width" "6px"
                , Attr.style "cursor" "col-resize"
                , onStartWindowResize onResize
                ]
                []
            , Html.div
                [ Attr.style "width"
                    rightPos
                , Attr.style
                    "height"
                    "calc(100vh - 40px)"
                , Attr.style "background-color" backgroundColor
                ]
                [ right ]
            ]


onStartWindowResize : (Int -> msg) -> Attribute msg
onStartWindowResize e =
    Events.on "mousedown" (D.map e pageX)


pageX : D.Decoder Int
pageX =
    D.field "pageX" D.int
