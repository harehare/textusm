module Dialog.Input exposing (Props, view)

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
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes as Attr
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
    Html.div [ Attr.css [ Style.dialogBackdrop ] ]
        [ Html.div
            [ Attr.css
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
            [ Html.div [ Attr.css [ Font.fontBold, padding2 zero (px 8) ] ] [ Html.text props.title ]
            , Html.div [ Attr.css [ Style.flexCenter, flexDirection column, padding <| px 8 ] ]
                [ Html.input
                    [ Attr.css
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
                                , textAlign right
                                , color Color.errorColor
                                ]
                            ]
                            [ Html.text (msg props.lang) ]

                    Nothing ->
                        Empty.view
                , Html.button
                    [ Attr.type_ "button"
                    , Attr.css [ Style.submit, marginTop <| px 8, Style.roundedSm ]
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
