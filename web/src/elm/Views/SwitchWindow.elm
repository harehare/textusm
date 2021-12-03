module Views.SwitchWindow exposing (view)

import Css exposing (backgroundColor, block, bottom, column, display, displayFlex, fixed, flexDirection, hex, int, none, position, px, relative, right, zIndex)
import Css.Media as Media exposing (withMedia)
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes as Attr exposing (css)
import Html.Styled.Events exposing (onClick)
import Models.Model exposing (WindowState(..))
import Style.Color as Color
import Style.Style as Style
import Views.Empty as Empty
import Views.Icon as Icon


view : (WindowState -> msg) -> String -> WindowState -> Html msg -> Html msg -> Html msg
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
            , case window of
                Editor ->
                    onClick (onSwitchWindow Preview)

                Preview ->
                    onClick (onSwitchWindow Editor)

                _ ->
                    Attr.class ""
            ]
            [ case window of
                Editor ->
                    Icon.visibility 20

                Preview ->
                    Icon.edit 20

                _ ->
                    Empty.view
            ]
        , Html.div
            [ css
                [ Style.hMain
                , Style.widthFull
                , withMedia [ Media.all [ Media.minWidth <| px 1024 ] ]
                    [ Style.heightFull ]
                ]
            ]
            [ Html.div
                [ css
                    [ Style.full
                    , case window of
                        Preview ->
                            display none

                        _ ->
                            display block
                    ]
                ]
                [ view1 ]
            , Html.div
                [ css
                    [ Style.full
                    , backgroundColor <| hex background
                    , case window of
                        Editor ->
                            display none

                        _ ->
                            display block
                    ]
                ]
                [ view2 ]
            ]
        ]
