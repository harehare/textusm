module View.SwitchWindow exposing (docs, view)

import Css
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes as Attr
import Html.Styled.Events exposing (onClick)
import Style.Breakpoint as Breakpoint
import Style.Color as Color
import Style.Style as Style
import Types.Color as Color
import Types.Window as Window exposing (Window)
import View.Empty as Empty
import View.Icon as Icon


view : { onSwitchWindow : Window -> msg, bgColor : Css.Color, window : Window } -> Html msg -> Html msg -> Html msg
view { onSwitchWindow, bgColor, window } view1 view2 =
    Html.div
        [ Attr.css
            [ Css.displayFlex
            , Css.flexDirection Css.column
            , Css.position Css.relative
            , Style.widthScreen
            , Color.bgMain
            ]
        ]
        [ Html.div
            [ Attr.css
                [ Css.displayFlex
                , Css.position Css.fixed
                , Style.flexCenter
                , Style.roundedFull
                , Color.bgAccent
                , Css.zIndex <| Css.int 50
                , Style.paddingSm
                , Style.shadowSm
                , Css.bottom <| Css.px 72
                , Css.right <| Css.px 16
                ]
            , if Window.isDisplayEditor window then
                onClick (onSwitchWindow window)

              else if Window.isDisplayPreview window then
                onClick (onSwitchWindow window)

              else
                Attr.class ""
            ]
            [ if Window.isDisplayEditor window then
                Icon.visibility 20

              else if Window.isDisplayPreview window then
                Icon.edit Color.white 20

              else
                Empty.view
            ]
        , Html.div
            [ Attr.css
                [ Breakpoint.style
                    [ Style.hMain
                    , Style.widthFull
                    ]
                    [ Breakpoint.large [ Style.heightFull ] ]
                ]
            ]
            [ Html.div
                [ Attr.css
                    [ Style.full
                    , if Window.isDisplayPreview window then
                        Css.display Css.none

                      else
                        Css.display Css.block
                    ]
                ]
                [ view1 ]
            , Html.div
                [ Attr.css
                    [ Style.full
                    , Css.backgroundColor bgColor
                    , if Window.isDisplayEditor window then
                        Css.display Css.none

                      else
                        Css.display Css.block
                    ]
                ]
                [ view2 ]
            ]
        ]


docs : Chapter x
docs =
    Chapter.chapter "SwitchWindow"
        |> Chapter.renderComponent
            (view
                { onSwitchWindow = \_ -> Actions.logAction "onSwitchWindow"
                , bgColor = Css.hex "#FFFFFF"
                , window = Window.showPreview <| Window.init 60
                }
                (Html.div [] [ Html.text "view1" ])
                (Html.div [] [ Html.text "view2" ])
                |> Html.toUnstyled
            )
