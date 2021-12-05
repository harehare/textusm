module Dialog.Input exposing (view)

import Css
    exposing
        ( border3
        , color
        , column
        , fixed
        , flexDirection
        , hex
        , left
        , marginTop
        , padding
        , padding2
        , pct
        , position
        , px
        , right
        , solid
        , textAlign
        , top
        , transforms
        , translateX
        , translateY
        , width
        , zero
        )
import Events
import Html.Styled exposing (Html, button, div, input, text)
import Html.Styled.Attributes exposing (classList, css, maxlength, placeholder, type_, value)
import Html.Styled.Events exposing (onClick, onInput)
import Message exposing (Lang, Message)
import Style.Color as Color
import Style.Font as Font
import Style.Style as Style
import Style.Text as Text
import Views.Empty as Empty
import Views.Spinner as Spinner


type alias Props msg =
    { title : String
    , errorMessage : Maybe Message
    , value : String
    , inProcess : Bool
    , lang : Lang
    , onInput : String -> msg
    , onEnter : msg
    }


view : Props msg -> Html msg
view props =
    div [ css [ Style.dialogBackdrop ] ]
        [ div
            [ css
                [ Color.bgDefault
                , Color.textColor
                , Style.shadowSm
                , position fixed
                , top <| pct 50
                , left <| pct 50
                , transforms [ translateX <| pct -50, translateY <| pct -50 ]
                , padding <| px 16
                , Style.roundedSm
                ]
            ]
            [ div [ css [ Font.fontBold, padding2 zero (px 8) ] ] [ text props.title ]
            , div [ css [ Style.flexCenter, flexDirection column, padding <| px 8 ] ]
                [ input
                    [ css
                        [ Css.batch
                            [ Style.inputLight
                            , Text.sm
                            , color <| hex "#555555"
                            , width <| px 305
                            ]
                        , Css.batch
                            [ case props.errorMessage of
                                Just _ ->
                                    border3 (px 3) solid Color.errorColor

                                Nothing ->
                                    Css.batch []
                            ]
                        ]
                    , if props.inProcess then
                        classList []

                      else
                        Events.onEnter props.onEnter
                    , type_ "password"
                    , placeholder "Enter password"
                    , maxlength 72
                    , value props.value
                    , onInput props.onInput
                    , if props.inProcess then
                        classList []

                      else
                        Events.onEnter props.onEnter
                    ]
                    []
                , case props.errorMessage of
                    Just msg ->
                        div
                            [ css
                                [ Style.widthFull
                                , Text.sm
                                , Font.fontBold
                                , textAlign right
                                , color Color.errorColor
                                ]
                            ]
                            [ text (msg props.lang) ]

                    Nothing ->
                        Empty.view
                , button
                    [ type_ "button"
                    , css [ Style.submit, marginTop <| px 8, Style.roundedSm ]
                    , if props.inProcess then
                        classList []

                      else
                        onClick props.onEnter
                    ]
                    [ if props.inProcess then
                        div [ css [ Style.widthFull, Style.flexCenter ] ] [ Spinner.small ]

                      else
                        text "Submit"
                    ]
                ]
            ]
        ]
