module Views.SplitWindow exposing (Props, view)

import Css exposing (absolute, alignItems, backgroundColor, borderBottomRightRadius, borderTopRightRadius, calc, center, colResize, cursor, display, displayFlex, height, hex, int, minus, none, plus, pointer, position, px, relative, right, top, vw, width, zIndex)
import Html.Styled as Html exposing (Attribute, Html)
import Html.Styled.Attributes exposing (css)
import Html.Styled.Events as Events
import Json.Decode as D
import Models.Color as Color
import Models.Model exposing (Window, WindowState(..))
import Style.Color as Color
import Style.Style as Style
import Views.Icon as Icon


type alias Props msg =
    { background : String
    , window : Window
    , onToggleEditor : WindowState -> msg
    , onResize : Int -> msg
    }


view : Props msg -> Html msg -> Html msg -> Html msg
view { onToggleEditor, onResize, background, window } left right =
    let
        ( leftPos, rightPos ) =
            case ( window.state, window.position > 0, window.position < 0 ) of
                ( Preview, _, _ ) ->
                    ( calc (px 0) minus (px 0), calc (vw 100) minus (px 40) )

                ( _, True, _ ) ->
                    ( calc (calc (vw 50) minus (px 20)) plus (px <| toFloat <| abs window.position)
                    , calc (calc (vw 50) minus (px 20)) minus (px <| toFloat <| abs window.position)
                    )

                ( _, _, True ) ->
                    ( calc (calc (vw 50) minus (px 20)) minus (px <| toFloat <| abs window.position)
                    , calc (calc (vw 50) minus (px 20)) plus (px <| toFloat <| abs window.position)
                    )

                _ ->
                    ( calc (vw 50) minus (px 20), calc (vw 50) minus (px 20) )
    in
    case window.state of
        Fullscreen ->
            Html.div
                [ css [ displayFlex, backgroundColor <| hex background ] ]
                [ Html.div [ css [ display none ] ] [ left ]
                , Html.div [ css [ Style.fullScreen ] ] [ right ]
                ]

        _ ->
            Html.div
                [ css [ displayFlex, Style.borderContent ] ]
                [ Html.div
                    [ css [ width leftPos, Style.hContent, Color.bgMain, position relative ] ]
                    [ left, toggleEditorButton window.state onToggleEditor ]
                , Html.div
                    [ css [ Color.bgMain, width <| px 20, cursor colResize ]
                    , onStartWindowResize onResize
                    ]
                    []
                , Html.div
                    [ css [ width rightPos, Style.hContent, backgroundColor <| hex background ] ]
                    [ right ]
                ]


toggleEditorButton : WindowState -> (WindowState -> msg) -> Html msg
toggleEditorButton state onToggleEditor =
    Html.div
        [ css
            [ position absolute
            , zIndex <| int 50
            , cursor pointer
            , top <| px 8
            , right <| px -36
            , borderTopRightRadius <| px 4
            , borderBottomRightRadius <| px 4
            , width <| px 16
            , height <| px 24
            , Color.bgMain
            ]
        ]
        [ case state of
            Both ->
                hideEditorButton (onToggleEditor Preview)

            _ ->
                showEditorButton (onToggleEditor Both)
        ]


showEditorButton : msg -> Html msg
showEditorButton m =
    Html.div [ css [ Style.full, displayFlex, alignItems center ], Events.onClick m ] [ Icon.angleRight Color.white 12 ]


hideEditorButton : msg -> Html msg
hideEditorButton m =
    Html.div [ css [ Style.full, displayFlex, alignItems center ], Events.onClick m ] [ Icon.angleLeft Color.white 12 ]


onStartWindowResize : (Int -> msg) -> Attribute msg
onStartWindowResize e =
    Events.on "mousedown" (D.map e pageX)


pageX : D.Decoder Int
pageX =
    D.field "pageX" D.int
