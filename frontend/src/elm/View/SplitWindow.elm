module View.SplitWindow exposing (docs, view)

import Css
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html.Styled as Html exposing (Attribute, Html)
import Html.Styled.Attributes as Attr
import Html.Styled.Events as Events
import Json.Decode as D
import Style.Color as Color
import Style.Style as Style
import Types.Color as Color
import Types.Settings exposing (splitDirection)
import Types.SplitDirection as SplitDirection exposing (SplitDirection)
import Types.Window as Window exposing (Window)
import View.Icon as Icon


view :
    { bgColor : Css.Color
    , window : Window
    , splitDirection : SplitDirection
    , onToggleEditor : Window -> msg
    , onResize : Int -> msg
    }
    -> Html msg
    -> Html msg
    -> Html msg
view { bgColor, window, splitDirection, onToggleEditor, onResize } left right =
    case splitDirection of
        SplitDirection.Horizontal ->
            let
                ( leftPos, rightPos ) =
                    if Window.isDisplayPreview window then
                        ( Css.calc (Css.px 0) Css.minus (Css.px 0), Css.calc (Css.vw 100) Css.minus (Css.px 40) )

                    else
                        case ( window.position > 0, window.position < 0 ) of
                            ( True, _ ) ->
                                ( Css.calc (Css.calc (Css.vw 50) Css.minus (Css.px 20)) Css.plus (Css.px <| toFloat <| abs window.position)
                                , Css.calc (Css.calc (Css.vw 50) Css.minus (Css.px 20)) Css.minus (Css.px <| toFloat <| abs window.position)
                                )

                            ( _, True ) ->
                                ( Css.calc (Css.calc (Css.vw 50) Css.minus (Css.px 20)) Css.minus (Css.px <| toFloat <| abs window.position)
                                , Css.calc (Css.calc (Css.vw 50) Css.minus (Css.px 20)) Css.plus (Css.px <| toFloat <| abs window.position)
                                )

                            _ ->
                                ( Css.calc (Css.vw 50) Css.minus (Css.px 20), Css.calc (Css.vw 50) Css.minus (Css.px 20) )
            in
            if Window.isFullscreen window then
                Html.div
                    [ Attr.css [ Css.displayFlex, Css.backgroundColor bgColor ] ]
                    [ Html.div [ Attr.css [ Css.display Css.none ] ] [ left ]
                    , Html.div [ Attr.css [ Style.fullScreen ] ] [ right ]
                    ]

            else
                Html.div
                    [ Attr.css [ Css.displayFlex ] ]
                    [ Html.div
                        [ Attr.css [ Css.width leftPos, Style.hContent, Color.bgMain, Css.position Css.relative ] ]
                        [ left, toggleVerticalButton window onToggleEditor ]
                    , Html.div
                        [ Attr.css [ Color.bgMain, Css.width <| Css.px 8, Css.cursor Css.colResize ]
                        , onResizePageX onResize
                        ]
                        []
                    , Html.div
                        [ Attr.css [ Css.width rightPos, Style.hContent, Css.backgroundColor bgColor ]
                        ]
                        [ right ]
                    ]

        SplitDirection.Vertical ->
            let
                ( topPos, bottomPos ) =
                    if Window.isDisplayPreview window then
                        ( Css.calc (Css.px 0) Css.minus (Css.px 0), Css.calc (Css.vh 100) Css.minus (Css.px 40) )

                    else
                        case ( window.position > 0, window.position < 0 ) of
                            ( True, _ ) ->
                                ( Css.calc (Css.calc (Css.vh 50) Css.minus (Css.px 20)) Css.plus (Css.px <| toFloat <| abs window.position)
                                , Css.calc (Css.calc (Css.vh 50) Css.minus (Css.px 20)) Css.minus (Css.px <| toFloat <| abs window.position)
                                )

                            ( _, True ) ->
                                ( Css.calc (Css.calc (Css.vh 50) Css.minus (Css.px 20)) Css.minus (Css.px <| toFloat <| abs window.position)
                                , Css.calc (Css.calc (Css.vh 50) Css.minus (Css.px 20)) Css.plus (Css.px <| toFloat <| abs window.position)
                                )

                            _ ->
                                ( Css.calc (Css.vh 50) Css.minus (Css.px 20), Css.calc (Css.vh 50) Css.minus (Css.px 20) )
            in
            if Window.isFullscreen window then
                Html.div
                    [ Attr.css [ Css.displayFlex, Css.backgroundColor bgColor, Css.flexDirection Css.column ] ]
                    [ Html.div [ Attr.css [ Css.display Css.none ] ] [ left ]
                    , Html.div [ Attr.css [ Style.fullScreen ] ] [ right ]
                    ]

            else
                Html.div
                    [ Attr.css [ Css.displayFlex, Css.flexDirection Css.column ] ]
                    [ Html.div
                        [ Attr.css [ Css.height topPos, Color.bgMain, Css.position Css.relative ] ]
                        [ left, toggleHorizontalButton window onToggleEditor ]
                    , Html.div
                        [ Attr.css [ Color.bgMain, Css.height <| Css.px 12, Css.minHeight <| Css.px 12, Css.cursor Css.rowResize ]
                        , onResizePageY onResize
                        ]
                        []
                    , Html.div
                        [ Attr.css [ Css.height bottomPos, Css.backgroundColor bgColor ]
                        ]
                        [ right ]
                    ]


hideEditorButton : msg -> Html msg
hideEditorButton m =
    Html.div [ Attr.css [ Style.full, Css.displayFlex, Css.alignItems Css.center ], Events.onClick m ] [ Icon.angleLeft Color.white 12 ]


onResizePageX : (Int -> msg) -> Attribute msg
onResizePageX e =
    Events.on "mousedown" (D.map e pageX)


onResizePageY : (Int -> msg) -> Attribute msg
onResizePageY e =
    Events.on "mousedown" (D.map e pageY)


pageX : D.Decoder Int
pageX =
    D.field "pageX" D.int


pageY : D.Decoder Int
pageY =
    D.field "pageY" D.int


showEditorButton : msg -> Html msg
showEditorButton m =
    Html.div [ Attr.css [ Style.full, Css.displayFlex, Css.alignItems Css.center ], Events.onClick m ] [ Icon.angleRight Color.white 12 ]


toggleVerticalButton : Window -> (Window -> msg) -> Html msg
toggleVerticalButton window onToggleEditor =
    if Window.isDisplayBoth window then
        Html.div
            [ Attr.css
                [ Css.position Css.absolute
                , Css.zIndex <| Css.int 50
                , Css.cursor Css.pointer
                , Css.top <| Css.px 8
                , Css.right <| Css.px -24
                , Css.borderTopRightRadius <| Css.px 4
                , Css.borderBottomRightRadius <| Css.px 4
                , Css.width <| Css.px 16
                , Css.height <| Css.px 24
                , Color.bgMain
                ]
            ]
            [ hideEditorButton (onToggleEditor <| Window.showPreview window) ]

    else
        Html.div
            [ Attr.css
                [ Css.position Css.absolute
                , Css.zIndex <| Css.int 50
                , Css.cursor Css.pointer
                , Css.top <| Css.px 8
                , Css.right <| Css.px -24
                , Css.borderTopRightRadius <| Css.px 4
                , Css.borderBottomRightRadius <| Css.px 4
                , Css.width <| Css.px 16
                , Css.height <| Css.px 24
                , Color.bgMain
                ]
            ]
            [ showEditorButton (onToggleEditor <| Window.showEditorAndPreview window) ]


toggleHorizontalButton : Window -> (Window -> msg) -> Html msg
toggleHorizontalButton window onToggleEditor =
    if Window.isDisplayBoth window then
        Html.div
            [ Attr.css
                [ Css.position Css.absolute
                , Css.zIndex <| Css.int 50
                , Css.cursor Css.pointer
                , Css.bottom <| Css.px -32
                , Css.left <| Css.px 8
                , Css.borderTopRightRadius <| Css.px 4
                , Css.borderBottomRightRadius <| Css.px 4
                , Css.width <| Css.px 16
                , Css.height <| Css.px 24
                , Color.bgMain
                , Css.transform <| Css.rotate (Css.deg 90)
                ]
            ]
            [ hideEditorButton (onToggleEditor <| Window.showPreview window) ]

    else
        Html.div
            [ Attr.css
                [ Css.position Css.absolute
                , Css.zIndex <| Css.int 50
                , Css.cursor Css.pointer
                , Css.top <| Css.px 8
                , Css.left <| Css.px 8
                , Css.borderTopRightRadius <| Css.px 4
                , Css.borderBottomRightRadius <| Css.px 4
                , Css.width <| Css.px 16
                , Css.height <| Css.px 24
                , Color.bgMain
                , Css.transform <| Css.rotate (Css.deg 90)
                ]
            ]
            [ showEditorButton (onToggleEditor <| Window.showEditorAndPreview window) ]


docs : Chapter x
docs =
    Chapter.chapter "SplithWindow"
        |> Chapter.renderComponent
            (view
                { onToggleEditor = \_ -> Actions.logAction "onToggleEditor"
                , onResize = \_ -> Actions.logAction "onResize"
                , bgColor = Css.hex "#FFFFFF"
                , window = Window.showEditorAndPreview <| Window.init 60
                , splitDirection = SplitDirection.Vertical
                }
                (Html.div [] [ Html.text "view1" ])
                (Html.div [] [ Html.text "view2" ])
                |> Html.toUnstyled
            )
