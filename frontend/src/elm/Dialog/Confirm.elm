module Dialog.Confirm exposing (ButtonConfig, Props, view)

import Css
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes as Attr
import Html.Styled.Events exposing (onClick)
import Style.Color as Color
import Style.Font as Font
import Style.Style as Style
import Style.Text as Text


type alias ButtonConfig msg =
    { text : String
    , onClick : msg
    }


type alias Props msg =
    { title : String
    , message : String
    , okButton : ButtonConfig msg
    , cancelButton : ButtonConfig msg
    }


view : Props msg -> Html msg
view { title, message, okButton, cancelButton } =
    Html.div [ Attr.css [ Style.dialogBackdrop ] ]
        [ Html.div
            [ Attr.css
                [ Color.bgDefault
                , Color.textColor
                , Style.shadowSm
                , Css.position Css.fixed
                , Css.top <| Css.pct 50
                , Css.left <| Css.pct 50
                , Css.maxWidth <| Css.px 320
                , Css.transforms [ Css.translateX <| Css.pct -50, Css.translateY <| Css.pct -50 ]
                , Css.padding <| Css.px 16
                , Style.roundedSm
                ]
            ]
            [ Html.div
                [ Attr.css
                    [ Text.lg
                    , Font.fontBold
                    , Css.paddingTop <| Css.rem 0.5
                    , Css.paddingBottom <| Css.rem 0.5
                    ]
                ]
                [ Html.text title ]
            , Html.div
                [ Attr.css
                    [ Css.paddingTop <| Css.rem 0.75
                    , Css.paddingBottom <| Css.rem 0.75
                    ]
                ]
                [ Html.text message ]
            , Html.div [ Attr.css [ Style.flexCenter, Style.gap4 ] ]
                [ Html.button
                    [ Attr.type_ "button"
                    , Attr.css [ Style.submit, Css.marginTop <| Css.px 8, Style.roundedSm ]
                    , onClick okButton.onClick
                    ]
                    [ Html.text okButton.text ]
                , Html.button
                    [ Attr.type_ "button"
                    , Attr.css [ Style.submit, Color.bgDisabled, Color.textDark, Css.marginTop <| Css.px 8, Style.roundedSm ]
                    , onClick cancelButton.onClick
                    ]
                    [ Html.text cancelButton.text ]
                ]
            ]
        ]
