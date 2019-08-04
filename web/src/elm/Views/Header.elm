module Views.Header exposing (view)

import Html exposing (Attribute, Html, a, div, header, img, input, text)
import Html.Attributes exposing (alt, class, href, id, placeholder, src, style, value)
import Html.Events exposing (keyCode, on, onBlur, onClick, onInput, stopPropagationOn)
import Json.Decode as D
import Maybe.Extra exposing (isJust)
import Models.Model exposing (Menu(..), Msg(..))
import Models.User exposing (User)
import Route exposing (Route(..))
import Styles
import Utils
import Views.Icon as Icon
import Views.Menu as Menu


view : Int -> Maybe User -> Route -> Maybe String -> Bool -> Bool -> Maybe Menu -> Html Msg
view width profile route t isEditTitle fullscreen menu =
    let
        title =
            t |> Maybe.withDefault ""
    in
    if fullscreen then
        header [] []

    else
        header
            [ class "main-header" ]
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
                            , style "width" "150px"
                            , style "font-weight" "400"
                            , style "padding" "2px"
                            ]
                            []

                    else
                        div
                            [ style "color" "#f4f4f4"
                            , style "max-width" "150px"
                            , style "text-overflow" "ellipsis"
                            , style "text-align" "left"
                            , style "cursor" "pointer"
                            , style "font-weight" "100"
                            , style "font-size" "16px"
                            , style "overflow" "hidden"
                            , style "margin-bottom" "2px"
                            , style "font-weight" "400"
                            , style "white-space" "nowrap"
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
                , if Utils.isPhone width then
                    div
                        [ style "padding" "0 8px"
                        , style "margin-right" "4px"
                        ]
                        []

                  else
                    div
                        [ style "font-size" "0.9rem"
                        , style "padding" "0 8px"
                        , style "font-weight" "400"
                        , style "margin-right" "8px"
                        ]
                        [ text "HELP" ]
                ]
            , div
                (Styles.flexCenter
                    ++ [ class "button"
                       , onClick OnCurrentShareUrl
                       ]
                )
                [ Icon.people 24
                , if Utils.isPhone width then
                    div
                        [ style "padding" "0 8px"
                        , style "margin-right" "4px"
                        ]
                        []

                  else
                    div
                        [ style "font-size" "0.9rem"
                        , style "padding" "0 8px"
                        , style "font-weight" "400"
                        , style "margin-right" "4px"
                        ]
                        [ text "SHARE" ]
                ]
            , if isJust profile then
                let
                    user =
                        profile
                            |> Maybe.withDefault
                                { displayName = ""
                                , email = ""
                                , photoURL = ""
                                , idToken = ""
                                , id = ""
                                }
                in
                div
                    (Styles.flexCenter
                        ++ [ class "button"
                           , stopPropagationOn "click" (D.succeed ( OpenMenu HeaderMenu, True ))
                           ]
                    )
                    [ div
                        [ style "font-size" "0.9rem"
                        , style "padding" "0 8px"
                        , style "font-weight" "400"
                        , style "margin-right" "4px"
                        ]
                        [ img
                            [ src user.photoURL
                            , style "width" "30px"
                            , style "margin-top" "4px"
                            , style "object-fit" "cover"
                            , style "border-radius" "4px"
                            ]
                            []
                        , case menu of
                            Just HeaderMenu ->
                                Menu.menu (Just "36px")
                                    Nothing
                                    Nothing
                                    (Just "5px")
                                    [ ( Logout, "SIGN OUT" )
                                    ]

                            _ ->
                                div [] []
                        ]
                    ]

              else
                div
                    (Styles.flexCenter
                        ++ [ class "button"
                           , onClick Login
                           ]
                    )
                    [ div
                        [ style "font-size" "0.9rem"
                        , style "padding" "0 8px"
                        , style "font-weight" "400"
                        , style "margin-right" "4px"
                        , style "width" "50px"
                        ]
                        [ text "SIGN IN" ]
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
