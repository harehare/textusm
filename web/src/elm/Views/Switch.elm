module Views.Switch exposing (view)

import Css
    exposing
        ( absolute
        , after
        , backgroundColor
        , borderBox
        , borderRadius
        , boxSizing
        , cursor
        , display
        , height
        , inlineBlock
        , int
        , left
        , opacity
        , pointer
        , position
        , property
        , px
        , relative
        , top
        , width
        , zIndex
        , zero
        )
import Html.Styled exposing (Html, div, input, label)
import Html.Styled.Attributes as Attr exposing (css, type_)
import Html.Styled.Events as E
import Style.Color as ColorStyle
import Style.Style as Style


view : Bool -> (Bool -> msg) -> Html msg
view check onCheck =
    div [ css [ Style.flexCenter, position relative ] ]
        [ input
            [ type_ "checkbox"
            , css
                [ position absolute
                , left zero
                , top zero
                , Style.full
                , zIndex <| int 5
                , opacity zero
                , cursor pointer
                ]
            , Attr.checked check
            , E.onCheck onCheck
            ]
            []
        , label
            [ css
                [ width <| px 32
                , height <| px 16
                , backgroundColor <| ColorStyle.disabledColor
                , position relative
                , display inlineBlock
                , borderRadius <| px 46
                , boxSizing borderBox
                , property "transition" "0.4s"
                , after
                    [ Style.emptyContent
                    , position absolute
                    , width <| px 16
                    , height <| px 16
                    , Style.roundedFull
                    , left zero
                    , top zero
                    , zIndex <| int 2
                    , ColorStyle.bgLight
                    , Style.shadowSm
                    , property "transition" "0.2s"
                    ]
                , if check then
                    Css.batch [ ColorStyle.bgActivity, after [ left <| px 16 ] ]

                  else
                    Css.batch []
                ]
            ]
            []
        ]
