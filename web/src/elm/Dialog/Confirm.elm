module Dialog.Confirm exposing (view)

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
import Html.Styled exposing (Html, button, div, text)
import Html.Styled.Attributes exposing (css, type_)
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
    div [ css [ Style.dialogBackdrop ] ]
        [ div
            [ css
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
            [ div
                [ css
                    [ Text.lg
                    , Font.fontBold
                    , paddingTop <| rem 0.5
                    , paddingBottom <| rem 0.5
                    ]
                ]
                [ text title ]
            , div
                [ css
                    [ paddingTop <| rem 0.75
                    , paddingBottom <| rem 0.75
                    ]
                ]
                [ text message ]
            , div [ css [ Style.flexCenter, Style.gap4 ] ]
                [ button
                    [ type_ "button"
                    , css [ Style.submit, marginTop <| px 8, Style.roundedSm ]
                    , onClick okButton.onClick
                    ]
                    [ text okButton.text ]
                , button
                    [ type_ "button"
                    , css [ Style.submit, Color.bgDisabled, Color.textDark, marginTop <| px 8, Style.roundedSm ]
                    , onClick cancelButton.onClick
                    ]
                    [ text cancelButton.text ]
                ]
            ]
        ]
