module Views.Header exposing (view)

import Html exposing (Attribute, Html, a, div, header, img, input, text)
import Html.Attributes exposing (alt, class, href, id, placeholder, src, style, value)
import Html.Events exposing (keyCode, on, onBlur, onClick, onInput)
import Json.Decode as D
import Models.Model exposing (Msg(..))
import Route exposing (Route(..))
import Styles
import Views.Icon as Icon


view : Route -> Maybe String -> Bool -> Bool -> Html Msg
view route t isEditTitle fullscreen =
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
                        "#323B46"
                   ]
            )
            [ div
                [ style "width" "100%"
                , style "height" "40px"
                , style "display" "flex"
                , style "align-items" "center"
                ]
                [ logo
                , if route /= Route.List then
                    if isEditTitle then
                        input
                            [ id "title"
                            , class "title"
                            , value title
                            , onInput EditTitle
                            , onBlur (EndEditTitle 13 False)
                            , onKeyDown EndEditTitle
                            , placeholder "UNTITLED"
                            , style "font-size" "16px"
                            , style "width" "200px"
                            , style "font-weight" "400"
                            ]
                            []

                    else
                        div
                            [ style "color" "#f4f4f4"
                            , style "max-width" "200px"
                            , style "text-overflow" "ellipsis"
                            , style "text-align" "left"
                            , style "cursor" "pointer"
                            , style "font-weight" "100"
                            , style "font-size" "16px"
                            , style "overflow" "hidden"
                            , style "margin-bottom" "2px"
                            , style "font-weight" "400"
                            , onClick StartEditTitle
                            ]
                            [ text
                                (if String.isEmpty title then
                                    "UNTITLED"

                                 else
                                    title
                                )
                            ]

                  else
                    div [] []
                ]
            , div
                (Styles.flexCenter
                    ++ [ class "button"
                       , onClick ShowHelp
                       ]
                )
                [ Icon.helpOutline 20
                , div
                    [ style "font-size" "0.9rem"
                    , style "padding" "0 8px"
                    , style "font-weight" "400"
                    , style "margin-right" "8px"
                    ]
                    [ text "Help" ]
                ]
            , div
                (Styles.flexCenter
                    ++ [ class "button"
                       , onClick OnCurrentShareUrl
                       ]
                )
                [ Icon.share "#F5F5F6" 18
                , div
                    [ style "font-size" "0.9rem"
                    , style "padding" "0 8px"
                    , style "font-weight" "400"
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
