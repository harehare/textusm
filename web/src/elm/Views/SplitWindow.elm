module Views.SplitWindow exposing (Props, view)

import Css exposing (absolute, alignItems, backgroundColor, borderBottomRightRadius, borderTopRightRadius, calc, center, colResize, cursor, display, displayFlex, height, hex, int, minus, none, plus, pointer, position, px, relative, right, top, vw, width, zIndex)
import Html.Styled as Html exposing (Attribute, Html)
import Html.Styled.Attributes exposing (css)
import Html.Styled.Events as Events
import Json.Decode as D
import Models.Color as Color
import Models.Window as Window exposing (Window)
import Style.Color as Color
import Style.Style as Style
import Views.Icon as Icon


type alias Props msg =
    { background : String
    , window : Window
    , onToggleEditor : Window -> msg
    , onResize : Int -> msg
    }


view : Props msg -> Html msg -> Html msg -> Html msg
view { background, window, onToggleEditor, onResize } left right =
    let
        ( leftPos, rightPos ) =
            if Window.isDisplayPreview window then
                ( calc (px 0) minus (px 0), calc (vw 100) minus (px 40) )

            else
                case ( window.position > 0, window.position < 0 ) of
                    ( True, _ ) ->
                        ( calc (calc (vw 50) minus (px 20)) plus (px <| toFloat <| abs window.position)
                        , calc (calc (vw 50) minus (px 20)) minus (px <| toFloat <| abs window.position)
                        )

                    ( _, True ) ->
                        ( calc (calc (vw 50) minus (px 20)) minus (px <| toFloat <| abs window.position)
                        , calc (calc (vw 50) minus (px 20)) plus (px <| toFloat <| abs window.position)
                        )

                    _ ->
                        ( calc (vw 50) minus (px 20), calc (vw 50) minus (px 20) )
    in
    if Window.isFullscreen window then
        Html.div
            [ css [ displayFlex, backgroundColor <| hex background ] ]
            [ Html.div [ css [ display none ] ] [ left ]
            , Html.div [ css [ Style.fullScreen ] ] [ right ]
            ]

    else
        Html.div
            [ css [ displayFlex ] ]
            [ Html.div
                [ css [ width leftPos, Style.hContent, Color.bgMain, position relative ] ]
                [ left, toggleEditorButton window onToggleEditor ]
            , Html.div
                [ css [ Color.bgMain, width <| px 20, cursor colResize ]
                , onStartWindowResize onResize
                ]
                []
            , Html.div
                [ css [ width rightPos, Style.hContent, backgroundColor <| hex background ] ]
                [ right ]
            ]


hideEditorButton : msg -> Html msg
hideEditorButton m =
    Html.div [ css [ Style.full, displayFlex, alignItems center ], Events.onClick m ] [ Icon.angleLeft Color.white 12 ]


onStartWindowResize : (Int -> msg) -> Attribute msg
onStartWindowResize e =
    Events.on "mousedown" (D.map e pageX)


pageX : D.Decoder Int
pageX =
    D.field "pageX" D.int


showEditorButton : msg -> Html msg
showEditorButton m =
    Html.div [ css [ Style.full, displayFlex, alignItems center ], Events.onClick m ] [ Icon.angleRight Color.white 12 ]


toggleEditorButton : Window -> (Window -> msg) -> Html msg
toggleEditorButton window onToggleEditor =
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
        [ if Window.isDisplayBoth window then
            hideEditorButton (onToggleEditor window)

          else
            showEditorButton (onToggleEditor window)
        ]
