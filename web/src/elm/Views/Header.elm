module Views.Header exposing (view)

import Html exposing (Attribute, Html, a, div, header, img, input, text)
import Html.Attributes exposing (alt, class, href, id, placeholder, src, style, value)
import Html.Events exposing (keyCode, on, onBlur, onClick, onInput)
import Json.Decode as D
import Models.Model exposing (Msg(..))
import Styles
import Views.Icon as Icon


view : Maybe String -> Bool -> Bool -> Html Msg
view t isEditTitle fullscreen =
    let
        title =
            t |> Maybe.withDefault ""
    in
    if fullscreen then
        header [] []

    else
        header
            (Styles.flexCenter
                ++ [ style "width"
                        "100vw"
                   , style "height"
                        "40px"
                   , style "background-color"
                        "#282C32"
                   , style "box-shadow"
                        "inset 0 -96px 48px -96px #282C32"
                   ]
            )
            [ div
                [ style "width" "100%"
                , style "height" "40px"
                , style "display" "flex"
                , style "align-items" "center"
                ]
                [ logo
                , if isEditTitle then
                    input
                        [ id "title"
                        , class "title"
                        , value title
                        , onInput EditTitle
                        , onBlur (EndEditTitle 13 False)
                        , onKeyDown EndEditTitle
                        , placeholder "UNTITLED"
                        , style "font-size" "1.1rem"
                        ]
                        []

                  else
                    div
                        [ style "color" "#f4f4f4"
                        , style "max-width" "250px"
                        , style "text-overflow" "ellipsis"
                        , style "text-align" "left"
                        , style "cursor" "pointer"
                        , style "font-weight" "100"
                        , style "font-size" "1.1rem"
                        , onClick StartEditTitle
                        ]
                        [ text
                            (if String.isEmpty title then
                                "UNTITLED"

                             else
                                title
                            )
                        ]
                ]
            , div
                (Styles.flexCenter
                    ++ [ style "color" "#F5F5F6"
                       , style "cursor" "pointer"
                       , style "margin-right" "8px"
                       , onClick OnShareUrl
                       ]
                )
                [ Icon.share 18
                , div
                    [ style "font-size" "0.9rem"
                    , style "padding" "0 8px"
                    ]
                    [ text "Share" ]
                ]
            ]


logo : Html Msg
logo =
    div
        [ style "width"
            "56px"
        , style "height"
            "40px"
        , style "display" "flex"
        , style "justify-content" "center"
        , style "align-items" "center"
        ]
        [ a [ href "/" ] [ img [ src "/images/logo.svg", style "width" "32px", alt "logo" ] [] ] ]


onKeyDown : (Int -> Bool -> msg) -> Attribute msg
onKeyDown tagger =
    on "keydown" (D.map2 tagger keyCode isComposing)


isComposing : D.Decoder Bool
isComposing =
    D.field "isComposing" D.bool
