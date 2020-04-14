module Views.Header exposing (view)

import Events exposing (onKeyDown)
import Html exposing (Html, a, div, header, img, input, span, text)
import Html.Attributes exposing (alt, class, href, id, placeholder, src, style, value)
import Html.Events exposing (onBlur, onClick, onInput, stopPropagationOn)
import Json.Decode as D
import Maybe.Extra exposing (isJust)
import Models.Model exposing (LoginProvider(..), Menu(..), Msg(..))
import Models.Text as Text exposing (Text)
import Models.Title as Title exposing (Title)
import Models.User exposing (User)
import Route exposing (Route(..))
import Views.Empty as Empty
import Views.Icon as Icon
import Views.Menu as Menu


view : Maybe User -> Route -> Title -> Bool -> Maybe Menu -> Text -> Html Msg
view profile route title fullscreen menu currentText =
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
                    if Title.isEdit title then
                        input
                            [ id "title"
                            , class "title"
                            , style "padding" "2px"
                            , style "color" "#f4f4f4"
                            , style "background-color" "var(--main-color)"
                            , style "border" "none"
                            , style "font-weight" "400"
                            , value <| Title.toString title
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
                            , style "display" "flex"
                            , style "align-items" "center"
                            , style "justify-content" "flex-start"
                            , onClick StartEditTitle
                            ]
                            [ text <| Title.toString title
                            , div
                                [ style "margin-left" "8px" ]
                                [ if Text.isChanged currentText then
                                    Icon.circle "#FEFEFE" 10

                                  else
                                    Empty.view
                                ]
                            ]

                  else
                    Empty.view
                ]
            , div
                [ class "button"
                , onClick <| NavRoute Help
                , style "padding" "8px"
                , style "display" "flex"
                , style "align-items" "center"
                ]
                [ Icon.helpOutline 20
                , span [ class "bottom-tooltip" ] [ span [ class "text" ] [ text "Help" ] ]
                ]
            , div
                [ class "button"
                , onClick OnCurrentShareUrl
                , style "padding" "8px"
                , style "display" "flex"
                , style "align-items" "center"
                ]
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
                    [ class "button"
                    , stopPropagationOn "click" (D.succeed ( OpenMenu HeaderMenu, True ))
                    , style "display" "flex"
                    , style "align-items" "center"
                    ]
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
                                    [ Menu.Item
                                        { e = Logout
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
                    [ class "button"
                    , stopPropagationOn "click" (D.succeed ( OpenMenu LoginMenu, True ))
                    , style "display" "flex"
                    , style "align-items" "center"
                    ]
                    [ div
                        [ style "font-size" "0.9rem"
                        , style "padding" "0 8px"
                        , style "font-weight" "400"
                        , style "margin-right" "4px"
                        , style "width" "55px"
                        ]
                        [ text "SIGN IN" ]
                    , case menu of
                        Just LoginMenu ->
                            Menu.menu (Just "30px")
                                Nothing
                                Nothing
                                (Just "5px")
                                [ Menu.Item
                                    { e = Login Google
                                    , title = "Google"
                                    , icon = Nothing
                                    }
                                , Menu.Item
                                    { e = Login Github
                                    , title = "Github"
                                    , icon = Nothing
                                    }
                                ]

                        _ ->
                            Empty.view
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
