module View.Switch exposing (docs, view)

import Css
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html.Styled as Html exposing (Html, div, input, label)
import Html.Styled.Attributes as Attr
import Html.Styled.Events as E
import Style.Color as ColorStyle
import Style.Style as Style


view : Bool -> (Bool -> msg) -> Html msg
view check onCheck =
    div [ Attr.css [ Style.flexCenter, Css.position Css.relative ] ]
        [ input
            [ Attr.type_ "checkbox"
            , Attr.css
                [ Css.position Css.absolute
                , Css.left Css.zero
                , Css.top Css.zero
                , Style.full
                , Css.zIndex <| Css.int 5
                , Css.opacity Css.zero
                , Css.cursor Css.pointer
                ]
            , Attr.checked check
            , E.onCheck onCheck
            ]
            []
        , label
            [ Attr.css
                [ Css.width <| Css.px 32
                , Css.height <| Css.px 16
                , Css.backgroundColor <| ColorStyle.disabledColor
                , Css.position Css.relative
                , Css.display Css.inlineBlock
                , Css.borderRadius <| Css.px 46
                , Css.boxSizing Css.borderBox
                , Css.property "transition" "0.4s"
                , Css.after
                    [ Style.emptyContent
                    , Css.position Css.absolute
                    , Css.width <| Css.px 16
                    , Css.height <| Css.px 16
                    , Style.roundedFull
                    , Css.left Css.zero
                    , Css.top Css.zero
                    , Css.zIndex <| Css.int 2
                    , ColorStyle.bgLight
                    , Style.shadowSm
                    , Css.property "transition" "0.2s"
                    ]
                , if check then
                    Css.batch [ ColorStyle.bgActivity, Css.after [ Css.left <| Css.px 16 ] ]

                  else
                    Css.batch []
                ]
            ]
            []
        ]


docs : Chapter x
docs =
    Chapter.chapter "Switch"
        |> Chapter.renderComponent
            (view True (\_ -> Actions.logAction "onCheck")
                |> Html.toUnstyled
            )
