module Dialog.Input exposing (Props, view)

import Css
import Events
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes as Attr
import Html.Styled.Events exposing (onClick, onInput)
import Message exposing (Lang, Message)
import Style.Color as Color
import Style.Font as Font
import Style.Style as Style
import Style.Text as Text
import View.Empty as Empty
import View.Spinner as Spinner


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
    Html.div [ Attr.css [ Style.dialogBackdrop ] ]
        [ Html.div
            [ Attr.css
                [ Color.bgDefault
                , Color.textColor
                , Style.shadowSm
                , Css.position Css.fixed
                , Css.top <| Css.pct 50
                , Css.left <| Css.pct 50
                , Css.transforms [ Css.translateX <| Css.pct -50, Css.translateY <| Css.pct -50 ]
                , Css.padding <| Css.px 16
                , Style.roundedSm
                ]
            ]
            [ Html.div [ Attr.css [ Font.fontBold, Css.padding2 Css.zero (Css.px 8) ] ] [ Html.text props.title ]
            , Html.div [ Attr.css [ Style.flexCenter, Css.flexDirection Css.column, Css.padding <| Css.px 8 ] ]
                [ Html.input
                    [ Attr.css
                        [ Css.batch
                            [ Style.inputLight
                            , Text.sm
                            , Css.color <| Css.hex "#555555"
                            , Css.width <| Css.px 305
                            ]
                        , Css.batch
                            [ case props.errorMessage of
                                Just _ ->
                                    Css.border3 (Css.px 3) Css.solid Color.errorColor

                                Nothing ->
                                    Css.batch []
                            ]
                        ]
                    , if props.inProcess then
                        Attr.classList []

                      else
                        Events.onEnter props.onEnter
                    , Attr.type_ "password"
                    , Attr.placeholder "Enter password"
                    , Attr.maxlength 72
                    , Attr.value props.value
                    , onInput props.onInput
                    , if props.inProcess then
                        Attr.classList []

                      else
                        Events.onEnter props.onEnter
                    ]
                    []
                , case props.errorMessage of
                    Just msg ->
                        Html.div
                            [ Attr.css
                                [ Style.widthFull
                                , Text.sm
                                , Font.fontBold
                                , Css.textAlign Css.right
                                , Css.color Color.errorColor
                                ]
                            ]
                            [ Html.text (msg props.lang) ]

                    Nothing ->
                        Empty.view
                , Html.button
                    [ Attr.type_ "button"
                    , Attr.css [ Style.submit, Css.marginTop <| Css.px 8, Style.roundedSm ]
                    , if props.inProcess then
                        Attr.classList []

                      else
                        onClick props.onEnter
                    ]
                    [ if props.inProcess then
                        Html.div [ Attr.css [ Style.widthFull, Style.flexCenter ] ] [ Spinner.view ]

                      else
                        Html.text "Submit"
                    ]
                ]
            ]
        ]
