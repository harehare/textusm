module Views.SwitchWindow exposing (view)

import Css exposing (backgroundColor, block, bottom, column, display, displayFlex, fixed, flexDirection, hex, int, none, position, px, relative, right, zIndex)
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes as Attr exposing (css)
import Html.Styled.Events exposing (onClick)
import Models.Window as Window exposing (Window)
import Style.Breakpoint as Breakpoint
import Style.Color as Color
import Style.Style as Style
import Views.Empty as Empty
import Views.Icon as Icon


view : (Window -> msg) -> String -> Window -> Html msg -> Html msg -> Html msg
view onSwitchWindow background window view1 view2 =
    Html.div
        [ css
            [ displayFlex
            , flexDirection column
            , position relative
            , Style.widthScreen
            , Color.bgMain
            ]
        ]
        [ Html.div
            [ css
                [ displayFlex
                , position fixed
                , Style.flexCenter
                , Style.roundedFull
                , Color.bgAccent
                , zIndex <| int 50
                , Style.paddingSm
                , Style.shadowSm
                , bottom <| px 72
                , right <| px 16
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
                Icon.edit 20

              else
                Empty.view
            ]
        , Html.div
            [ css
                [ Breakpoint.style
                    [ Style.hMain
                    , Style.widthFull
                    ]
                    [ Breakpoint.large [ Style.heightFull ] ]
                ]
            ]
            [ Html.div
                [ css
                    [ Style.full
                    , if Window.isDisplayPreview window then
                        display none

                      else
                        display block
                    ]
                ]
                [ view1 ]
            , Html.div
                [ css
                    [ Style.full
                    , backgroundColor <| hex background
                    , if Window.isDisplayEditor window then
                        display none

                      else
                        display block
                    ]
                ]
                [ view2 ]
            ]
        ]
