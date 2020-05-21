module Views.Header exposing (view)

import Data.DiagramItem exposing (DiagramItem)
import Data.Session as Session exposing (Session)
import Data.Text as Text exposing (Text)
import Data.Title as Title exposing (Title)
import Events exposing (onKeyDown)
import Html exposing (Html, a, div, header, img, input, span, text)
import Html.Attributes exposing (alt, class, href, id, placeholder, src, style, value)
import Html.Events exposing (onBlur, onClick, onInput, stopPropagationOn)
import Json.Decode as D
import MD5
import Maybe.Extra exposing (isJust)
import Models.Model as Page exposing (LoginProvider(..), Menu(..), Msg(..), Page(..))
import Route exposing (Route(..))
import Url
import Views.Empty as Empty
import Views.Icon as Icon
import Views.Menu as Menu


type alias HeaderProps =
    { session : Session
    , page : Page
    , title : Title
    , isFullscreen : Bool
    , currentDiagram : Maybe DiagramItem
    , menu : Maybe Menu
    , currentText : Text
    }


view : HeaderProps -> Html Msg
view props =
    if props.isFullscreen then
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
                [ div
                    [ style "width"
                        "56px"
                    , style "height"
                        "40px"
                    , style "display" "flex"
                    , style "justify-content" "center"
                    , style "align-items" "center"
                    ]
                    [ a [ href "/" ] [ img [ src "/images/logo.svg", style "width" "32px", alt "logo" ] [] ] ]
                , if props.page /= Page.List then
                    if Title.isEdit props.title then
                        input
                            [ id "title"
                            , class "title"
                            , style "padding" "2px"
                            , style "color" "#f4f4f4"
                            , style "background-color" "var(--main-color)"
                            , style "border" "none"
                            , style "font-size" "1.1rem"
                            , style "font-weight" "400"
                            , style "font-family" "'Nunito Sans', sans-serif"
                            , value <| Title.toString props.title
                            , onInput EditTitle
                            , onBlur (EndEditTitle Events.keyEnter False)
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
                            , style "font-size" "1.1rem"
                            , style "align-items" "center"
                            , style "justify-content" "flex-start"
                            , onClick StartEditTitle
                            ]
                            [ text <| Title.toString props.title
                            , div
                                [ style "margin-left" "8px" ]
                                [ if Text.isChanged props.currentText then
                                    Icon.circle "#FEFEFE" 10

                                  else
                                    Empty.view
                                ]
                            ]

                  else
                    Empty.view
                ]
            , if isJust props.currentDiagram then
                div
                    [ class "button"
                    , onClick <| NavRoute Tag
                    , style "padding" "8px"
                    , style "display" "flex"
                    , style "align-items" "center"
                    ]
                    [ Icon.tag 17
                    , span [ class "bottom-tooltip" ] [ span [ class "text" ] [ text "Tags" ] ]
                    ]

              else
                Empty.view
            , div
                [ class "button"
                , onClick <| NavRoute Route.Help
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
            , if Session.isSignedIn props.session then
                let
                    user =
                        Session.getUser props.session

                    defaultImageUrl =
                        Url.percentEncode (Maybe.map .photoURL user |> Maybe.withDefault "")

                    digest =
                        MD5.hex (Maybe.map .email user |> Maybe.withDefault "")
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
                            [ src <| "https://www.gravatar.com/avatar/" ++ digest ++ "?d=" ++ defaultImageUrl ++ "&s=40"
                            , style "width" "30px"
                            , style "margin-top" "4px"
                            , style "object-fit" "cover"
                            , style "border-radius" "50%"
                            ]
                            []
                        , case props.menu of
                            Just HeaderMenu ->
                                Menu.menu (Just "36px")
                                    Nothing
                                    Nothing
                                    (Just "5px")
                                    [ Menu.Item
                                        { e = NoOp
                                        , title = Maybe.map .email user |> Maybe.withDefault ""
                                        }
                                    , Menu.Item
                                        { e = SignOut
                                        , title = "SIGN OUT"
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
                    , case props.menu of
                        Just LoginMenu ->
                            Menu.menu (Just "30px")
                                Nothing
                                Nothing
                                (Just "5px")
                                [ Menu.Item
                                    { e = SignIn Google
                                    , title = "Google"
                                    }
                                , Menu.Item
                                    { e = SignIn Github
                                    , title = "Github"
                                    }
                                ]

                        _ ->
                            Empty.view
                    ]
            ]
