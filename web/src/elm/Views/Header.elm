module Views.Header exposing (view)

import Html exposing (Attribute, Html, a, div, header, img, input, span, text)
import Html.Attributes exposing (alt, class, href, id, placeholder, src, style, value)
import Html.Events exposing (keyCode, on, onBlur, onClick, onInput, stopPropagationOn)
import Json.Decode as D
import Maybe.Extra exposing (isJust)
import Models.Model exposing (Menu(..), Msg(..))
import Models.User exposing (User)
import Route exposing (Route(..))
import Styles
import Utils
import Views.Empty as Empty
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
                            , style "padding" "2px"
                            , style "color" "#f4f4f4"
                            , style "background-color" "var(--main-color)"
                            , style "border" "none"
                            , style "font-weight" "400"
                            , value title
                            , onInput EditTitle
                            , onBlur (EndEditTitle 13 False)
                            , onKeyDown EndEditTitle
                            , placeholder "UNTITLED"
                            ]
                            []

                    else
                        div
                            [ class "title"
                            , style "color" "#f4f4f4"
                            , style "text-overflow" "ellipsis"
                            , style "text-align" "left"
                            , style "cursor" "pointer"
                            , style "overflow" "hidden"
                            , style "white-space" "nowrap"
                            , style "font-weight" "400"
                            , style "padding" "2px"
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
                    Empty.view
                ]
            , div
                (Styles.flexCenter
                    ++ [ class "button"
                       , onClick <| NavRoute Help
                       , style "padding" "8px"
                       ]
                )
                [ Icon.helpOutline 20
                , span [ class "bottom-tooltip" ] [ span [ class "text" ] [ text "Help" ] ]
                ]
            , div
                (Styles.flexCenter
                    ++ [ class "button"
                       , onClick OnCurrentShareUrl
                       , style "padding" "8px"
                       ]
                )
                [ Icon.people 24
                , span [ class "bottom-tooltip" ] [ span [ class "text" ] [ text "Share" ] ]
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
                                    [ { e = Logout
                                      , title = "SIGN OUT"
                                      , icon = Nothing
                                      }
                                    ]

                            _ ->
                                Empty.view
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
