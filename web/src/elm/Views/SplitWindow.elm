module Views.SplitWindow exposing (view)

import Html exposing (Attribute, Html)
import Html.Attributes as Attr
import Html.Events as Events
import Json.Decode as D
import Models.Color as Color
import Models.Model exposing (Window, WindowState(..))
import Views.Icon as Icon


type alias Props msg =
    { backgroundColor : String
    , window : Window
    , onToggleEditor : WindowState -> msg
    , onResize : Int -> msg
    }


view : Props msg -> Html msg -> Html msg -> Html msg
view { onToggleEditor, onResize, backgroundColor, window } left right =
    let
        ( leftPos, rightPos ) =
            case ( window.state, window.position > 0, window.position < 0 ) of
                ( Preview, _, _ ) ->
                    ( "0px", "calc(100vw - 40px)" )

                ( _, True, _ ) ->
                    ( "calc((100vw - 40px) / 2 + "
                        ++ String.fromInt (abs window.position)
                        ++ "px)"
                    , "calc((100vw - 40px) / 2 - "
                        ++ String.fromInt (abs window.position)
                        ++ "px)"
                    )

                ( _, _, True ) ->
                    ( "calc((100vw - 40px) / 2 - "
                        ++ String.fromInt (abs window.position)
                        ++ "px)"
                    , "calc((100vw - 40px) / 2 + "
                        ++ String.fromInt (abs window.position)
                        ++ "px)"
                    )

                _ ->
                    ( "calc((100vw - 40px) / 2)", "calc((100vw - 40px) / 2)" )
    in
    case window.state of
        Fullscreen ->
            Html.div
                [ Attr.class "flex", Attr.style "background-color" backgroundColor ]
                [ Html.div [ Attr.class "hidden" ] [ left ]
                , Html.div [ Attr.class "full-screen" ] [ right ]
                ]

        _ ->
            Html.div
                [ Attr.class "flex p-xxs border-content" ]
                [ Html.div
                    [ Attr.style "width"
                        leftPos
                    , Attr.class "h-content"
                    , Attr.class "bg-main"
                    , Attr.class "bg-main"
                    , Attr.class "relative"
                    ]
                    [ left, toggleEditorButton window.state onToggleEditor ]
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
                    , Attr.class "h-content"
                    , Attr.style "background-color" backgroundColor
                    ]
                    [ right ]
                ]


toggleEditorButton : WindowState -> (WindowState -> msg) -> Html msg
toggleEditorButton state onToggleEditor =
    Html.div
        [ Attr.class "absolute z-50 cursor-pointer"
        , Attr.style "top" "8px"
        , Attr.style "right" "-22px"
        , Attr.style "border-top-right-radius" "4px"
        , Attr.style "border-bottom-right-radius" "4px"
        , Attr.style "width" "16px"
        , Attr.style "height" "24px"
        , Attr.style "background-color" "var(--main-color)"
        ]
        [ case state of
            Both ->
                hideEditorButton (onToggleEditor Preview)

            _ ->
                showEditorButton (onToggleEditor Both)
        ]


showEditorButton : msg -> Html msg
showEditorButton m =
    Html.div [ Attr.class "w-full h-full flex items-center", Events.onClick m ] [ Icon.angleRight Color.white 12 ]


hideEditorButton : msg -> Html msg
hideEditorButton m =
    Html.div [ Attr.class "w-full h-full flex items-center", Events.onClick m ] [ Icon.angleLeft Color.white 12 ]


onStartWindowResize : (Int -> msg) -> Attribute msg
onStartWindowResize e =
    Events.on "mousedown" (D.map e pageX)


pageX : D.Decoder Int
pageX =
    D.field "pageX" D.int
