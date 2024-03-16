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
import Types.Window as Window exposing (Window)
import View.Icon as Icon


view :
    { bgColor : Css.Color
    , window : Window
    , onToggleEditor : Window -> msg
    , onResize : Int -> msg
    }
    -> Html msg
    -> Html msg
    -> Html msg
view { bgColor, window, onToggleEditor, onResize } left right =
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
                [ left, toggleEditorButton window onToggleEditor ]
            , Html.div
                [ Attr.css [ Color.bgMain, Css.width <| Css.px 8, Css.cursor Css.colResize ]
                , onStartWindowResize onResize
                ]
                []
            , Html.div
                [ Attr.css [ Css.width rightPos, Style.hContent, Css.backgroundColor bgColor ]
                ]
                [ right ]
            ]


hideEditorButton : msg -> Html msg
hideEditorButton m =
    Html.div [ Attr.css [ Style.full, Css.displayFlex, Css.alignItems Css.center ], Events.onClick m ] [ Icon.angleLeft Color.white 12 ]


onStartWindowResize : (Int -> msg) -> Attribute msg
onStartWindowResize e =
    Events.on "mousedown" (D.map e pageX)


pageX : D.Decoder Int
pageX =
    D.field "pageX" D.int


showEditorButton : msg -> Html msg
showEditorButton m =
    Html.div [ Attr.css [ Style.full, Css.displayFlex, Css.alignItems Css.center ], Events.onClick m ] [ Icon.angleRight Color.white 12 ]


toggleEditorButton : Window -> (Window -> msg) -> Html msg
toggleEditorButton window onToggleEditor =
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
        [ if Window.isDisplayBoth window then
            hideEditorButton (onToggleEditor <| Window.showPreview window)

          else
            showEditorButton (onToggleEditor <| Window.showEditorAndPreview window)
        ]


docs : Chapter x
docs =
    Chapter.chapter "SplithWindow"
        |> Chapter.renderComponent
            (view
                { onToggleEditor = \_ -> Actions.logAction "onToggleEditor"
                , onResize = \_ -> Actions.logAction "onResize"
                , bgColor = Css.hex "#FFFFFF"
                , window = Window.showEditorAndPreview <| Window.init 60
                }
                (Html.div [] [ Html.text "view1" ])
                (Html.div [] [ Html.text "view2" ])
                |> Html.toUnstyled
            )
