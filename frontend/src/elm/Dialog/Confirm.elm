module Dialog.Confirm exposing (ButtonConfig, Props, view)

import Css
    exposing
        ( fixed
        , left
        , marginTop
        , maxWidth
        , padding
        , paddingBottom
        , paddingTop
        , pct
        , position
        , px
        , rem
        , top
        , transforms
        , translateX
        , translateY
        )
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
                , position fixed
                , top <| pct 50
                , left <| pct 50
                , maxWidth <| px 320
                , transforms [ translateX <| pct -50, translateY <| pct -50 ]
                , padding <| px 16
                , Style.roundedSm
                ]
            ]
            [ Html.div
                [ Attr.css
                    [ Text.lg
                    , Font.fontBold
                    , paddingTop <| rem 0.5
                    , paddingBottom <| rem 0.5
                    ]
                ]
                [ Html.text title ]
            , Html.div
                [ Attr.css
                    [ paddingTop <| rem 0.75
                    , paddingBottom <| rem 0.75
                    ]
                ]
                [ Html.text message ]
            , Html.div [ Attr.css [ Style.flexCenter, Style.gap4 ] ]
                [ Html.button
                    [ Attr.type_ "button"
                    , Attr.css [ Style.submit, marginTop <| px 8, Style.roundedSm ]
                    , onClick okButton.onClick
                    ]
                    [ Html.text okButton.text ]
                , Html.button
                    [ Attr.type_ "button"
                    , Attr.css [ Style.submit, Color.bgDisabled, Color.textDark, marginTop <| px 8, Style.roundedSm ]
                    , onClick cancelButton.onClick
                    ]
                    [ Html.text cancelButton.text ]
                ]
            ]
        ]
